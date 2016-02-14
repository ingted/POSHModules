FUNCTION SQLTYP {
    PARAM(
        $TYP
        , $VALUE
        , $MAXLEN
    )
    return $typ, $(SWITCH(,$VALUE){
        $null {[System.DBNull]::Value}
        default {$value}
    }), $MAXLEN
}

FUNCTION bigint {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Int64) $VALUE
}
FUNCTION binary {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Binary) $VALUE
}
FUNCTION bit {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Boolean) $VALUE
}
FUNCTION char {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::String) $VALUE
}
FUNCTION date {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::DateTime) $VALUE
}
FUNCTION datetime {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::DateTime) $VALUE
}
FUNCTION datetime2 {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::DateTime) $VALUE
}
FUNCTION datetimeoffset {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::DateTimeOffset) $VALUE
}
FUNCTION decimal {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Decimal) $VALUE
}
FUNCTION float {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Double) $VALUE
}

FUNCTION geography {
	PARAM(
		$VALUE
	)
	SQLTYP ([Microsoft.SqlServer.Types.SqlGeography]) $VALUE
}

FUNCTION geometry {
	PARAM(
		$VALUE
	)
	SQLTYP ([Microsoft.SqlServer.Types.SqlGeometry]) $VALUE
}


FUNCTION hierarchyid {
	PARAM(
		$VALUE
	)
	SQLTYP ([Microsoft.SqlServer.Types.SqlHierarchyId]) $VALUE
}

FUNCTION image {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Binary) $VALUE
}
FUNCTION int {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Int32) $VALUE
}
FUNCTION money {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Decimal) $VALUE
}
FUNCTION nchar {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::String) $VALUE
}
FUNCTION ntext {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::String) $VALUE
}
FUNCTION numeric {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Decimal) $VALUE
}
FUNCTION nvarchar {
	PARAM(
		$VALUE
        , $MAXLEN
	)
	SQLTYP ([System.Data.DbType]::String) $VALUE $MAXLEN
}
FUNCTION real {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Single) $VALUE
}
FUNCTION smalldatetime {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::DateTime) $VALUE
}
FUNCTION smallint {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Int16) $VALUE
}
FUNCTION smallmoney {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Decimal) $VALUE
}

FUNCTION sql_variant {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Object]) $VALUE
}

FUNCTION sysname {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::String) $VALUE
}
FUNCTION text {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::String) $VALUE
}

FUNCTION time {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.TimeSpan]) $VALUE
}

FUNCTION timestamp {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Binary) $VALUE
}
FUNCTION tinyint {
	PARAM(
		$VALUE
	)
	SQLTYP ([byte]) $VALUE
}
FUNCTION uniqueidentifier {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Guid) $(SWITCH(,$VALUE){$null{$VALUE} DEFAULT{[GUID] $VALUE}})
}
FUNCTION varbinary {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::Binary) $VALUE
}
FUNCTION varchar {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::String) $VALUE
}
FUNCTION xml {
	PARAM(
		$VALUE
	)
	SQLTYP ([System.Data.DbType]::String) $VALUE
}



$funcExp = @(
    "SQLTYP",
    "image", "text", "uniqueidentifier", "date", "time", "datetime2",
    "datetimeoffset", "tinyint", "smallint", "int", "smalldatetime", "real",
    "money", "datetime", "float", "sql_variant", "ntext", "bit", "decimal",
    "numeric", "smallmoney", "bigint", "hierarchyid", "geometry", "geography",
    "varbinary", "varchar", "binary", "char", "timestamp", "nvarchar", "nchar",
    "xml", "sysname")


$varExp = @()

Export-ModuleMember -Function $($funcExp) #-Variable $($varExp)