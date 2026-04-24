from tests.fixtures.abc_unique import UniqueBase


class UniqueImpl(UniqueBase):

    def unique_method(self):
        return "only one"
