from typing import Generic, TypeVar
import abc

OfferType = TypeVar("OfferType")


class BusinessOfferRepository(Generic[OfferType], abc.ABC):

    @abc.abstractmethod
    def find(
        self,
        center_code: str,
        service_date: str,
    ) -> OfferType: ...


class SomeMixin:
    pass


# Concrete implementation with single base
class SqlBusinessOfferRepository(BusinessOfferRepository):

    def find(self, center_code: str, service_date: str):
        return None


# Concrete implementation with multiple bases
class CachedBusinessOfferRepository(SomeMixin, BusinessOfferRepository):

    def find(self, center_code: str, service_date: str):
        return None
