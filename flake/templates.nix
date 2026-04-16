{
  flake.templates = {
    consumer = {
      path = ../templates/consumer;
      description = "Template for using and extending an NGI Forge instance";
    };
    provider = {
      path = ../templates/provider;
      description = "Template for self hosting you own NGI Forge instance";
    };
  };
}
