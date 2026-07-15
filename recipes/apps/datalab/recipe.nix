{
  pkgs,
  lib,
  ...
}:

{
  apps.datalab = {
    displayName = "DataLab";
    description = "Open-source Platform for Scientific and Technical Data Processing and Visualization.";
    usage = ''
      DataLab is an open-source platform for scientific signal and image processing and visualization.
      It can be used as a standalone application, embedded in your own software, or remote-controlled via its XML-RPC API.

      #### GUI

      Launch the DataLab desktop application:

      ```bash
      datalab
      ```

      #### API

      First, [enter the Nix shell](app/datalab#run-shell), which provides a Python environment with DataLab already installed.

      In the example below, we use a [remote proxy](https://datalab-platform.com/en/features/advanced/proxy.html#module-datalab.control.proxy) to programmatically create and display some data.

      Second, start the DataLab GUI (which also launches its XML-RPC server):

      ```bash
      datalab >/dev/null &
      ```

      Third, run the following script:

      ```python
      # test.py
      ${lib.readFile ./test.py}
      ```

      ```bash
      python ./test.py
      ```

      Lastly, navigate to the DataLab GUI and you should find `my-signal` in the Signal Panel and `my-image` in the Image Panel.

      For more scripting examples, please refer to the [API documentation](https://datalab-platform.com/en/features/advanced/proxy.html).
    '';

    icon = ./icon.svg;

    links = {
      website = "https://datalab-platform.com";
      source = "https://github.com/DataLab-Platform/DataLab";
      docs = "https://datalab-platform.com";
    };

    ngi.grants = {
      Commons = [
        "DataLab-DEW"
      ];
      Core = [
        "DataLab"
      ];
    };

    programs = {
      mainPackage = pkgs.datalab;
      packages = with pkgs; [
        (python3.withPackages (
          ps: with ps; [
            datalab-platform
          ]
        ))
        datalab # gui
      ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };

    # TODO:
    # test.programs = {
    #   script = ''
    #     xvfb-run datalab &
    #     DATALAB_PID=$!
    #
    #     # wait for port to be open
    #     sleep 20
    #
    #     python ${./test.py}
    #
    #     kill $DATALAB_PID 2>/dev/null || true
    #   '';
    #   packages = with pkgs; [
    #     xvfb-run
    #   ];
    # };
  };
}
