USE DBSLab
GO

CREATE TRIGGER [dbo].[UpdateAmount]
ON [dbo].[OrderItem]
AFTER 
INSERT, DELETE, UPDATE
AS 
BEGIN

	--SET NOCOUNT ON;

	declare @quantity_inserted int, @quantity_deleted int, 
			@productcode varchar(10), @orderid int,@orderitemid int,
			@amount_inserted decimal(8,2), @amount_deleted decimal(8,2),
			@discounted_amount_inserted decimal(8,2), @discounted_amount_deleted decimal(8,2),
			@amount_nett decimal(8,2),@discounted_amount_nett decimal(8,2),
			@product_price decimal(5,2), @product_discount decimal(4,2)

    IF NOT EXISTS(SELECT * FROM INSERTED)
    BEGIN    -- DELETE
	
			Select	@productcode = ProductCode, @quantity_deleted = Quantity,
					@orderid=OrderID
			From deleted

			Select @product_price = Price, @product_discount = Discount
			From Product
			Where ProductCode = @productcode

			Set @product_discount = Isnull(@product_discount,0)/100

			Set @amount_deleted = (@product_price * @quantity_deleted)
			Set @discounted_amount_deleted = (@amount_deleted - (@amount_deleted * @product_discount))
	
			Update [Order] 
			Set AmountBeforeDiscount = (Isnull(AmountBeforeDiscount,0) - @amount_deleted),
				AmountAfterDiscount = (Isnull(AmountAfterDiscount,0) - @discounted_amount_deleted)
			Where OrderID =@orderid

    END
	ELSE
    BEGIN
        IF NOT EXISTS(SELECT * FROM DELETED)
        BEGIN
		-- INSERT
		
			Select	@productcode = ProductCode, @quantity_inserted = Quantity,
					@orderid=OrderID
			From inserted

			Select @product_price = Price, @product_discount = Discount
			From Product
			Where ProductCode = @productcode

			Set @product_discount = Isnull(@product_discount,0)/100

			Set @amount_inserted = (@product_price * @quantity_inserted)
			Set @discounted_amount_inserted = (@amount_inserted - (@amount_inserted * @product_discount))
	
			Update [Order] 
			Set AmountBeforeDiscount = (Isnull(AmountBeforeDiscount,0) + @amount_inserted),
				AmountAfterDiscount = (Isnull(AmountAfterDiscount,0) + @discounted_amount_inserted)
			Where OrderID =@orderid

        END
		ELSE
        BEGIN
		-- UPDATE
		
			Select	@productcode = ProductCode, @quantity_deleted = Quantity,
					@orderid=OrderID
			From deleted

			Select	@quantity_inserted = Quantity
			From inserted

			Select @product_price = Price, @product_discount = Discount
			From Product
			Where ProductCode = @productcode

			Set @product_discount = Isnull(@product_discount,0)/100
			
			Set @amount_deleted = (@product_price * @quantity_deleted)
			Set @discounted_amount_deleted = (@amount_deleted - (@amount_deleted * @product_discount))

			Set @amount_inserted = (@product_price * @quantity_inserted)
			Set @discounted_amount_inserted = (@amount_inserted - (@amount_inserted * @product_discount))
	
			Set @amount_nett = (@amount_inserted - @amount_deleted)
			Set @discounted_amount_nett = (@discounted_amount_inserted - @discounted_amount_deleted)

			Update [Order] 
			Set AmountBeforeDiscount = (Isnull(AmountBeforeDiscount,0) + @amount_nett),
				AmountAfterDiscount = (Isnull(AmountAfterDiscount,0) + @discounted_amount_nett)
			Where OrderID =@orderid
		END
    END

END
