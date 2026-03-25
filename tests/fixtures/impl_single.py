from tests.fixtures.abc_simple import Animal


class Dog(Animal):

    def speak(self):
        return "Woof!"

    def move(self):
        return "run"
