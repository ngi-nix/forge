from dataclasses import dataclass


@dataclass
class Screenshot:
    url: str
    caption: str = ""
    default: bool = False
    hash: str = ""
    # The downloaded original image in the store.
    path: str = ""
