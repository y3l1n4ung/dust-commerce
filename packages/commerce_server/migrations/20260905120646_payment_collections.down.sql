-- Reverts only payment_collections; SQLx orders dependency-safe downs.
DROP TABLE payment_collections;
