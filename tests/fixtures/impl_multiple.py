from tests.fixtures.abc_simple import Animal


class Cat(Animal):
    """Implements both abstract methods."""

    def speak(self):
        return "Meow!"

    def move(self):
        return "prowl"


class Bird(Animal):
    """Implements speak but not move (still abstract)."""

    def speak(self):
        return "Tweet!"


class Rock(object):
    """Not a subclass of Animal at all."""

    def speak(self):
        return "..."
