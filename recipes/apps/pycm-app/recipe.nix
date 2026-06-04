{
  pkgs,
  ...
}:
{
  apps.pycm = {
    displayName = "PyCM";
    description = "Machine learning post-processing and analysis library to evaluate algorithm performance.";
    usage = ''
      PyCM is an open-source Python library designed to systematically evaluate, quantify, and report the performance of machine learning algorithms.

      To use it, launch python and import the library:

      ```python
      from pycm import ConfusionMatrix
      cm = ConfusionMatrix(actual_vector=[1, 1, 2, 2, 2], predict_vector=[1, 2, 2, 2, 1])
      print(cm)
      ```

      For more examples and detailed API documentation, please refer to https://pycm.io/doc.

      This environment also includes `jupyterlab`, `matplotlib`, and `seaborn` so you can interactively explore PyCM visually and plot the confusion matrices out-of-the-box (`cm.plot()`).

      ```bash
      jupyter-lab
      ```

      ```python
      import matplotlib.pyplot as plt
      from pycm import ConfusionMatrix
      cm = ConfusionMatrix(actual_vector=[1, 1, 2, 2, 2], predict_vector=[1, 2, 2, 2, 1])
      cm.plot()
      cm.plot(cmap=plt.cm.Greens, number_label=True, normalized=True)
      ```
    '';

    icon = ./icon.svg;

    links = {
      website = "https://pycm.io";
      docs = "https://pycm.io/doc";
      source = "https://github.com/sepandhaghighi/pycm";
    };

    ngi.grants = {
      Review = [ "PyCM" ];
      Commons = [ "PyCM-API" ];
    };

    programs = {
      packages = [
        (pkgs.python3.withPackages (pp: [
          pp.pycm
          pp.matplotlib
          pp.seaborn
          pp.jupyterlab
        ]))
      ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      python -c '
      from pycm import ConfusionMatrix
      cm = ConfusionMatrix(actual_vector=[1, 1, 2, 2, 2], predict_vector=[1, 2, 2, 2, 1])
      assert cm.classes == [1, 2]
      '
    '';
  };
}
