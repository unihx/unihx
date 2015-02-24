package unihx.pvt.macros;
import haxe.macro.Expr;

class StructHelper
{
	public static function with(fields:Array<String>, clsName:ComplexType, ethis:Expr, expr:Expr):Expr
	{
		switch (expr.expr)
		{
			case EObjectDecl(declFieldsArr):
				var declFields = new Map();
				{
					for (f in declFieldsArr)
					{
						if (declFields.exists(f.field))
							throw new Error('Duplicate field definition: ${f.field}', f.expr.pos);
						else if (fields.indexOf(f.field) == -1)
							throw new Error('Extra field constructor: ${f.field}', f.expr.pos);
						declFields[f.field] = f.expr;
					}
				}
				var ctorArgs = fields.map(function(f) {
					if (declFields.exists(f))
					{
						return declFields[f];
					} else {
						return macro @:pos(expr.pos) $ethis.$f;
					}
				});
				var type = switch (clsName)
				{
					case TPath(p):
						p;
					case _:
						throw 'assert';
				}

				return { expr:ENew(type, ctorArgs), pos:expr.pos };
			case _:
				throw new Error("The `with' macro expects an anonymous object declaration as its argument", expr.pos);
		}
	}
}
