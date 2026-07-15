import numpy as np
from datalab.control.proxy import RemoteProxy

proxy = RemoteProxy()
proxy.add_signal(
    "my-signal", xdata=np.array([1.0, 2.0, 3.0]), ydata=np.array([4.0, 5.0, -1.0])
)
proxy.add_image("my-image", data=np.random.rand(256, 256))
print(proxy.get_object_titles())
