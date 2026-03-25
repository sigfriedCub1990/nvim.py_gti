import abc


class FlagRepo(abc.ABC):

    @abc.abstractmethod
    def is_active(self, flag_name: str) -> bool: ...

    @abstractmethod
    def get_flags(self) -> list: ...
