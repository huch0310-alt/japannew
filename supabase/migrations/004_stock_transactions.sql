CREATE TABLE stock_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id),
    quantity_change INTEGER NOT NULL,
    reason TEXT NOT NULL,
    order_id UUID REFERENCES orders(id),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_stock_trans_product ON stock_transactions(product_id);
CREATE INDEX idx_stock_trans_created ON stock_transactions(created_at);

CREATE OR REPLACE FUNCTION update_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- 减少库存
    UPDATE products
    SET stock = stock - NEW.quantity
    WHERE id = NEW.product_id;

    -- 记录库存流水
    INSERT INTO stock_transactions (product_id, quantity_change, reason, order_id, created_by)
    VALUES (NEW.product_id, -NEW.quantity, 'ORDER', NEW.order_id, NEW.created_by);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_item_stock_update
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_stock();
