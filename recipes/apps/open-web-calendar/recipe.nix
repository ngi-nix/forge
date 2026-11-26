{
  forge-lib,
  config,
  pkgs,
  lib,
  ...
}:

let
  app = config.apps.open-web-calendar;
  usageSnippets = forge-lib.snippets.usage app;

  pythonEnv = pkgs.open-web-calendar.python.withPackages (ps: [
    (ps.toPythonModule pkgs.open-web-calendar)
    ps.gunicorn
  ]);
in

{
  pkgs.open-web-calendar = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.open-web-calendar;
    };
  };

  apps.open-web-calendar = {
    displayName = "Open Web Calendar";
    description = "Customizable & embeddable web calendar.";
    longDescription = ''
      The Open Web Calendar stack is an open-source set of Python libraries and programs which read and write calendars based on the iCalendar standard. It also aggregates public and private web calendars into a customizable view that can be embedded in a website.
    '';

    categories = with forge-lib.categories; [
      Calendar
    ];

    data = {
      exampleTemplate = "https://open-web-calendar.quelltext.eu/assets/templates/rooms.json";
      exampleCalendar = "https://open-web-calendar.quelltext.eu/assets/calendars/christmas.ics";
      templatesUrl = "https://open-web-calendar.quelltext.eu/templates";
      calendarsUrl = "https://github.com/niccokunzmann/open-web-calendar/tree/master/docs/assets/calendars";
      webUrl = "http://localhost:${toString app.services.components.web.endpoints.web.forwardedPort}";
    };

    usage = ''
      > [!NOTE]
      > You can try Open Web Calendar from the [official hosted instance](https://open-web-calendar.hosted.quelltext.eu) before running it locally.

      First, ${usageSnippets.run-container} or ${usageSnippets.run-nixos}.

      Then, once the service is ready, open the web interface: [${app.data.webUrl}](${app.data.webUrl})

      ##### Preview an example calendar

      Open the [rooms example](${app.data.webUrl}/calendar.html?specification_url=${app.data.exampleTemplate}) to see a week view with three calendars.

      You can find more examples, with live previews and specifications, in the [examples page](${app.data.templatesUrl}) and ICS files in the [calendar assets directory](${app.data.calendarsUrl}).

      ##### Create your own calendar

      First, open the [editor page](${app.data.webUrl}) and optinally add one or more ICS URLs.
      Next, customize your calendar by using the drop-down menu at the bottom of the page to move between the configuration sections and change the options as you go.

      Once you're done, go to the "Use & Embed" section or click on the button with the same name and the resulting calendar URL and iframe will be printed.
      To see the result, either open the link in a new tab or copy the iframe code and embed it in a web page.

      ##### Advanced customization

      You can also configure Open Web Calendar programmatically using [API endpoints and parameters](https://open-web-calendar.quelltext.eu/dev/api/) for a more flexible customization.
      For example, to customize the Christmas calendar, run:

      ```bash
      curl --get --silent --show-error \
        --data-urlencode "url=${app.data.exampleCalendar}" \
        --data-urlencode "title=Christmas" \
        --data-urlencode "timezone=Europe/Berlin" \
        --data-urlencode "date=2024-12-24" \
        --data-urlencode "tab=week" \
        --write-out '%{url_effective}\n' \
        --output /dev/null \
        "${app.data.webUrl}/index.html"
      ```

      What this does is pass the calendar configuration as query parameters.
      Then, `--output /dev/null` discards the editor page and `--write-out` (see [curl docs](https://curl.se/docs/manpage.html#-w:~:text=url%5Feffective)) prints the URL curl requested instead, so the command outputs just the encoded editor URL:

      ```
      http://localhost:5000/index.html?url=https%3A%2F%2Fopen-web-calendar.quelltext.eu%2Fassets%2Fcalendars%2Fchristmas.ics&title=Christmas&timezone=Europe%2FBerlin&date=2024-12-24&tab=week
      ```

      This is the same URL that would appear in the "Use & Embed" section of the editor, so you can open it in a new tab or paste it into an iframe.

      ${usageSnippets.see-docs}
    '';

    links = {
      website = "https://open-web-calendar.quelltext.eu";
      source = "https://github.com/niccokunzmann/open-web-calendar";
      docs = "https://open-web-calendar.quelltext.eu";
    };

    ngi.grants = {
      Core = [
        "OpenWebCalendar"
        "OpenWebCalendar-recurring"
      ];
    };

    icon = ./icon.svg;

    parameters = {
      port = {
        value = 5000;
        description = "Port of the Open Web Calendar web interface.";
      };
    };

    services = {
      components.web = {
        process = {
          command = "${pythonEnv}/bin/gunicorn";
          argv = [
            "--bind"
            "0.0.0.0:${toString app.parameters.port}"
            "open_web_calendar.app:app"
          ];
          packages = [ pythonEnv ];
        };

        healthcheck = {
          enable = true;
          test = [
            "curl"
            "-fs"
            "${app.data.webUrl}/index.html"
          ];
          packages = [ pkgs.curl ];
          interval = "3s";
          timeout = "3s";
          startPeriod = "10s";
          retries = 10;
        };

        endpoints = {
          web = {
            port = app.parameters.port;
          };
        };
      };

      runtimes = {
        container = {
          enable = true;
        };
        nixos = {
          enable = true;
        };
      };
    };

    test.services = {
      script = ''
        curl="curl --retry 10 --retry-max-time 120 --retry-all-errors"
        $curl "${app.data.webUrl}/index.html" | grep "Open Web Calendar"
      '';
    };
  };
}
