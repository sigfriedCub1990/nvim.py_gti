import abc


class Shape(metaclass=abc.ABCMeta):

    @abc.abstractmethod
    def area(self):
        """Return the area."""
        pass

    @abc.abstractmethod
    def perimeter(self):
        """Return the perimeter."""
        pass
