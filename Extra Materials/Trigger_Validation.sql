USE DBSLab
GO

CREATE TRIGGER [dbo].[ValidateStockQuantity]
ON [dbo].[OrderItem]
INSTEAD OF
INSERT
AS 
Begin

Declare @quantity_in_stock int, @quantity_ordered int, 
        @productcode varchar(10), @orderid int

Select @orderid=OrderID, @productcode=ProductCode, 
       @quantity_ordered = Quantity
From Inserted

Select @quantity_in_stock = QuantityInStock
From Product
Where ProductCode= @productcode

If @quantity_in_stock >= @quantity_ordered
Begin
INSERT INTO [dbo].[OrderItem] ([OrderID],[ProductCode],Quantity)
VALUES   (@orderid, @productcode,@quantity_ordered)

UPDATE Product
SET QuantityInStock = QuantityInStock -@quantity_ordered
where ProductCode = @productcode

End
Else
Begin
Print 'Not enough stock for the product:' + @productcode + '.Order Rejected.'
Print 'Currently we have only ' + convert(varchar,@quantity_in_stock) + ' units'
End
End

select * from [order] where OrderID=1
select * from [OrderItem] where OrderID=1
select * from [Product] where ProductCode='P100'

insert into OrderItem (ProductCode,OrderID,Quantity)
values ('P100',1,10)

select * from [order] where OrderID=1
select * from [OrderItem] where OrderID=1
select * from [Product] where ProductCode='P100'