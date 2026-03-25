from typing import Generic, TypeVar
import abc

OfferType = TypeVar("OfferType")


class BusinessOfferRepository(Generic[OfferType], abc.ABC):

    @abc.abstractmethod
    def find(self, center_code: str) -> OfferType: ...


class BusinessOffer:
    pass


# Concrete implementation inheriting with type parameter filled in
class SqlBusinessOfferRepository(BusinessOfferRepository[BusinessOffer]):

    def find(self, center_code: str) -> BusinessOffer:
        return BusinessOffer()


# Multiple bases, subscript form
class CachedBusinessOfferRepository(object, BusinessOfferRepository[BusinessOffer]):

    def find(self, center_code: str) -> BusinessOffer:
        return BusinessOffer()
