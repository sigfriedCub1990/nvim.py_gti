from abc import ABC, abstractmethod


class Animal(ABC):

    @abstractmethod
    def speak(self):
        """Make a sound."""
        pass

    @abstractmethod
    def move(self):
        """Move around."""
        pass

    def breathe(self):
        """Not abstract."""
        return "inhale/exhale"
