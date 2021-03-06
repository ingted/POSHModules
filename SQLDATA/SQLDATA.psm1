[reflection.assembly]::LoadFile("C:\Windows\Microsoft.NET\assembly\GAC_MSIL\System.Net.NetworkInformation\v4.0_4.0.0.0__b03f5f7f11d50a3a\System.Net.NetworkInformation.dll")

function Get-MSSQLData{
    param(
        $connection = "Data Source=localhost\ods01;Initial Catalog=ods;Persist Security Info=True;Integrated Security=SSPI;"
        , [string] $sql = "SELECT getdate() a"
        , [hashtable] $params = @{}
        , [hashtable] $OutputParams = @{}
        , [hashtable] $IOParams = @{}
        , [hashtable] $ReturnParams = @{}
        , [int] $Timeout = 50
        , [int] $connTimeout = 300
        , [string] $returnVar = ''
        , [string] $iexOnTheFly = ""
        , [BOOL] $IFCLOSE = $true
        , $specified_conn = $null
        , $dynSQLGen = 1
        , $commandType = "Text"
        , $SQLUSEER
        , $SQLPWD
    )
    if($specified_conn -eq $null){
        $MSSQLConn = Get-MSSQLConn $connection -__timeOut__ $connTimeout -__u__ $SQLUSEER -__p__ $SQLPWD

        if($MSSQLConn.eval -eq 1){
            if($MSSQLConn.returnValue.Value.State -ne "Open"){return (returnMsgError openConnError notOpen)}
        } else {return $MSSQLConn}
        $specified_conn = $MSSQLConn.returnValue.Value
    }
    
    try {
        $readcmd = New-Object System.Data.SqlClient.SqlCommand($sql, $specified_conn)
        $readcmd.CommandType = [System.Data.CommandType]::$commandType
        if($params.count -gt 0){
            $commonP = @{}
            $params.keys | ?{$_ -NOTMATCH "__tvp_type__"} | %{
                $key = $_
                $commonP[$key] = New-Object System.Data.SqlClient.SqlParameter
                $commonP[$key].ParameterName = $key                
                IF(($params.$key -ne $null) -and ($params.$key -ne [System.DBNull]::Value)){
                    
                    switch($params.$key.gettype()){
                        {$_ -eq [data.datatable]}{
                            $commonP[$key].SqlDbType = [System.Data.SqlDbType]::Structured
                            $commonP[$key].TypeName = $params["$key" + "__tvp_type__"]
                        }
                        default{ 
                            $commonP[$key].DbType = $nativeTyp2dbTyp[$params.$key.gettype()]
                        } 
                        #$params.$_[0] #$nativeTyp2dbTyp[$params.$_.gettype()]                    
                    }
                    $commonP[$key].value = $params.$key #[1] #$params.$_
                    $commonP[$key].SIZE = $nativeTyp2dbLen[$params.$key.gettype()] #$params.$_[2] #$params.$_
                } else {
                    $commonP[$key].value = [System.DBNull]::Value
                }
                [VOID] $readcmd.Parameters.Add($commonP[$key])
            }
        }
        if($ReturnParams.count -eq 1){
            $rtnP = @{}
            $ReturnParams.keys | %{
                $rtnP[$_] = New-Object System.Data.SqlClient.SqlParameter
                $rtnP[$_].ParameterName = $_
                $rtnP[$_].direction = [System.Data.ParameterDirection]::ReturnValue
                [VOID] $readcmd.Parameters.Add($rtnP[$_])
            }
        } elseif ($ReturnParams.count -eq 0){
        } else {return (returnMsgError returnParamsError returnValueMoreThanOne)}
        if($OutputParams.count -gt 0){
            $outP = @{}
            $OutputParams.keys | %{
                $outP[$_] = New-Object System.Data.SqlClient.SqlParameter
                $outP[$_].ParameterName = $_
                $outP[$_].direction = [System.Data.ParameterDirection]::Output
                #$outP[$_].DbType = $OutputParams.$_[0] #$nativeTyp2dbTyp[$IOParams.$_.gettype()]
                $outP[$_].DbType = $nativeTyp2dbTyp[$OutputParams.$_.gettype()]
                $outP[$_].SIZE = $nativeTyp2dbLen[$OutputParams.$_.gettype()]
                #$outP[$_].value = $OutputParams.$_[1]
                [VOID] $readcmd.Parameters.Add($outP[$_])                
            }
        }        
        if($IOParams.count -gt 0){
            $ioP = @{}
            $IOParams.keys | %{
                $iosp = New-Object System.Data.SqlClient.SqlParameter
                $iosp.direction = [System.Data.ParameterDirection]::InputOutput
                $iosp.ParameterName = $_
                #IF(($IOParams.$_ -ne $null) -and ($IOParams.$_ -ne [System.DBNull]::Value)){
                    $iosp.DbType = $nativeTyp2dbTyp[$IOParams.$_.gettype()] #$IOParams.$_[0] #$nativeTyp2dbTyp[$IOParams.$_.gettype()]
                    $iosp.value = $IOParams.$_ #[1] #$IOParams.$_
                    $iosp.SIZE = $nativeTyp2dbLen[$IOParams.$_.gettype()] #$IOParams.$_[2]
                #} else {
                #    $ioP[$_].value = [System.DBNull]::Value
                #}
                $ioP[$_] = [ref] $iosp
                [VOID] $readcmd.Parameters.Add($ioP[$_].Value)
            }
        }   

        $readcmd.CommandTimeout = $Timeout
         
        $da = New-Object System.Data.SqlClient.SqlDataAdapter($readcmd)
        $da.MissingSchemaAction = [System.data.MissingSchemaAction]::AddWithKey
        
        $cmdBuilder = New-Object System.data.sqlclient.sqlcommandbuilder($da)
        $CmdFailed = @()

        
        IF(!($dynSQLGen % 2)){
            try {$da.DeleteCommand = $cmdBuilder.GetDeleteCommand()
            } catch [Exception] {$CmdFailed += returnHashError getBuilderCmdError getDelCmdFailed}        
        }

        IF(!($dynSQLGen % 3)){
            try {$da.UpdateCommand = $cmdBuilder.GetUpdateCommand()
            } catch [Exception] {$CmdFailed += returnHashError getBuilderCmdError getUpdCmdFailed}        
        }

        IF(!($dynSQLGen % 5)){
            try {$da.InsertCommand = $cmdBuilder.GetInsertCommand()
            } catch [Exception] {$CmdFailed += returnHashError getBuilderCmdError getInsCmdFailed}        
        }
        #>
        <#
        try {$da.DeleteCommand = $cmdBuilder.GetDeleteCommand()
        } catch [Exception] {$CmdFailed += returnHashError getBuilderCmdError getDelCmdFailed}
        try {$da.UpdateCommand = $cmdBuilder.GetUpdateCommand()
        } catch [Exception] {$CmdFailed += returnHashError getBuilderCmdError getUpdCmdFailed}
        try {$da.InsertCommand = $cmdBuilder.GetInsertCommand()
        } catch [Exception] {$CmdFailed += returnHashError getBuilderCmdError getInsCmdFailed}
        #>
        $ds = New-Object System.Data.Dataset
        if($iexOnTheFly -ne ""){iex $iexOnTheFly}

        try {
            $fillRst = $da.fill($dS)
        } catch [System.Management.Automation.MethodInvocationException] {
            if($_.exception -match "does not implement IComparable interface"){
                $fillRst = $da.fill($dS)
            }
        } catch [exception] {
            return (returnHashError getDataError queryFailed)
        }
        IF($IFCLOSE){
            $specified_conn.close()
        }
        $rtnExec = [psobject] $ds
        Add-Member -InputObject $rtnExec -MemberType NoteProperty -Name commonP -Value $commonP
        Add-Member -InputObject $rtnExec -MemberType NoteProperty -Name outP -Value $outP
        Add-Member -InputObject $rtnExec -MemberType NoteProperty -Name ioP -Value $ioP
        Add-Member -InputObject $rtnExec -MemberType NoteProperty -Name rtnP -Value $rtnP
        Add-Member -InputObject $rtnExec -MemberType NoteProperty -Name adapter -Value $da
        Add-Member -InputObject $rtnExec -MemberType NoteProperty -Name connection -Value $connection
        Add-Member -InputObject $rtnExec -MemberType NoteProperty -Name SQLConn -Value $specified_conn
        Add-Member -InputObject $rtnExec -MemberType NoteProperty -Name fillRst -Value $fillRst
        Add-Member -InputObject $rtnExec -MemberType NoteProperty -Name CmdFailedError -Value $CmdFailed
        
        if($returnVar -eq ''){
            return (returnRefSuccess filled fillInvoked ([ref] $rtnExec))
        } else {
            return (returnRefSuccess filled returnIexReturnVarStr ([ref] $(iex $returnVar)))
        } 
        
    } catch [exception] {return (returnHashError getDataError queryFailed)}

}

function Get-MSSQLConn{
    param(
        $__connStr__
        , $__u__
        , $__p__
        , [int] $__timeOut__ = 15
    )
    try {
        if($__connStr__ -match "Connection\sTimeout"){
            $__connStr__ = $__connStr__ -replace "Connection\sTimeout=([^;\b]+)", "Connection Timeout=$__timeOut__"
        } else {
            $__connStr__ = $__connStr__ -replace "(?<!;)$", ";" -replace ";$", ";Connection Timeout=$__timeOut__;"
        }

        if($__u__ -eq $null){
            IF($__connStr__ -match "((UID)|(UserID)|(User))=(?<u>[^;]+)?;"){
                $__u__match = $Matches.u
                $__connStr__ = $__connStr__ -replace $Matches[0], ""
            } ELSE {
                $__u__match = $null
            }
        }
        if($__p__ -eq $null){
            IF($__connStr__ -match "((Password)|(PWD))=(?<p>[^;]+)?;"){
                $__p__match = $Matches.p
                $__connStr__ = $__connStr__ -replace $Matches[0], ""
            } ELSE {
                $__p__match = $null
            }
        }
        $__conn__ = $(switch($__connStr__){
            {$_ -is [string]}{
                New-Object System.Data.SqlClient.SqlConnection($__connStr__); continue
            }
            {$_ -is [System.Data.SqlClient.SqlConnection]}{
                $__connStr__; continue
            }
            default {
                #throw error
                New-Object System.Data.SqlClient.SqlConnection("Data Source=localhost;Initial Catalog=master;Persist Security Info=True;Integrated Security=SSPI;Connection Timeout=15")
            }
        })
        IF(($__u__ -eq $null) -AND ($__p__ -eq $null) -AND ($__u__match -EQ $NULL) -AND ($__p__match -EQ $NULL)){
        } ELSEif(($__u__ -eq $null) -or ($__p__ -eq $null)){
            $__conn__.Credential = Get-SqlCred -username $__u__match -password $__p__match
        } else {
            $__conn__.Credential = Get-SqlCred -username $__u__ -password $__p__
        }
        #Test-Connection -ComputerName $__conn__.DataSource
        $ping = New-Object System.Net.NetworkInformation.Ping
        if($__conn__.DataSource -notmatch "localdb"){
            if($ping.Send(($__conn__.DataSource -REPLACE "((\\.*)|(,.*))", ""), 500).Status -ne [System.Net.NetworkInformation.IPStatus]::Success){
                returnHashError openConnError openFailed
            } else {
                $__conn__.open()
                return (returnRefSuccess opened openInvoked ([ref] $__conn__))
            }
        } else {
            $__conn__.open()
            return (returnRefSuccess opened openInvoked ([ref] $__conn__))
        }
    }
    catch [exception] {return (returnHashError openConnError openFailed)}
}

function returnRefSuccess{
    param(
        [string] $successTypeName = $(throw "pleaseProvideTypeName")
        , [string] $msg = $(throw "pleaseProvideMessage")
        , [ref] $obj = $(throw "pleaseProvideReturnObj")
    )
    $rtn = returnSuccess $successTypeName $msg
    $rtn["returnValue"] = $obj
    return $rtn
}

function returnSuccess{
    param(
        [string] $successTypeName = $(throw "pleaseProvideTypeName")
        , [string] $msg = $(throw "pleaseProvideMessage")
    )
    return @{
        eval = 1
        ; $successTypeName = @{msg = $msg}
    }
}

function returnHashError{
    param(
        [string] $errorTypeName = $(throw "pleaseProvideTypeName")
        , [string] $msg = $(throw "pleaseProvideMessage")
        , $errobj = $_
    )
    return @{
        eval = 0
        ; $errorTypeName = @{
            msg = $msg
            ; PositionMessage = $errobj.InvocationInfo.PositionMessage
            ; ScriptLineNumber = $errobj.InvocationInfo.ScriptLineNumber
            ; OffsetInLine = $errobj.InvocationInfo.OffsetInLine
            ; Exception = $errobj.Exception
        }
    }
}

function returnHashRefError{
    param(
        [string] $errorTypeName = $(throw "pleaseProvideTypeName")
        , [string] $msg = $(throw "pleaseProvideMessage")
        , [ref] $obj = $(throw "pleaseProvideReturnObj")
        , $errobj = $_
    )
    $rtn = returnHashError $errorTypeName $msg $errobj
    $rtn["returnValue"] = $obj
    return $rtn
}

function returnMsgError{
    param(
        [string] $errorTypeName = $(throw "pleaseProvideTypeName")
        , [string] $msg = $(throw "pleaseProvideMessage")
    )
    return @{eval = 0; $errorTypeName = @{msg = $msg}}
}

function Get-PassCred { 
    param(
        $username = "administrator",
        $password = $null
    )
    if($password -eq $null){
        $pass = $Host.UI.ReadLineAsSecureString()
    } else {
        $pass = ConvertTo-SecureString -force -AsPlainText -string $password
    } 
    $return = New-Object System.Management.Automation.PSCredential -ArgumentList $username ,$pass 
    $return 
} 

function Get-SqlCred { 
    param(
        $username = "administrator",
        $password = $null
    )
    if($password -eq $null){
        $pass = $Host.UI.ReadLineAsSecureString()
    } else {
        $pass = ConvertTo-SecureString -force -AsPlainText -string $password
        $pass.MakeReadOnly()
    } 
    $return = New-Object System.Data.SqlClient.SqlCredential -ArgumentList $username ,$pass 
    $return 
} 



function Exec-MSSQLData {
    param(
        $connection = "Data Source=localhost\ods01;Initial Catalog=ods;Persist Security Info=True;Integrated Security=SSPI;"
        , [string] $sql = "sp_helpdb"
        , [hashtable] $params = @{}
        , [hashtable] $IOParams = @{}
        , [int] $Timeout = 300
        , [int] $connTimeout = 15
        , [switch] $debug
        , [string] $iexOnTheFly = ""
        , [BOOL] $ifclose = $true
        , $specified_conn = $null
        , $commandType = "Text"
        , $SQLUSEER
        , $SQLPWD
    )
    if($specified_conn -eq $null){
        $MSSQLConn = Get-MSSQLConn $connection -__timeOut__ $connTimeout -__u__ $SQLUSEER -__p__ $SQLPWD

        if($MSSQLConn.eval -eq 1){
            if($MSSQLConn.returnValue.Value.State -ne "Open"){return (returnMsgError openConnError notOpen)}
        } else {return $MSSQLConn}
        $specified_conn = $MSSQLConn.returnValue.Value
    }

    try{
        $execcmd = New-Object System.Data.SqlClient.SqlCommand($sql, $specified_conn)
        $execcmd.CommandType = [System.Data.CommandType]::$commandType 
        if($params.count -ne 0){
            $commonP = @{}
            $params.keys | %{
                $commonP[$_] = New-Object System.Data.SqlClient.SqlParameter
                $commonP[$_].ParameterName = $_
                $commonP[$_].value = $params.$_
                [VOID] $execcmd.Parameters.Add($commonP[$_])
            }
        }

        if($IOParams.count -gt 0){
            $ioP = @{}
            $IOParams.keys | %{
                $iosp = New-Object System.Data.SqlClient.SqlParameter
                $iosp.direction = [System.Data.ParameterDirection]::InputOutput
                $iosp.ParameterName = $_
                IF(($IOParams.$_ -ne $null) -and ($IOParams.$_ -ne [System.DBNull]::Value)){
                    $iosp.DbType = $nativeTyp2dbTyp[$IOParams.$_.gettype()] #$IOParams.$_[0] #$nativeTyp2dbTyp[$IOParams.$_.gettype()]
                    $iosp.value = $IOParams.$_ #[1] #$IOParams.$_
                    $iosp.SIZE = $nativeTyp2dbTyp[$IOParams.$_.gettype()] #$IOParams.$_[2]
                } else {
                    $ioP[$_].value = [System.DBNull]::Value
                }
                $ioP[$_] = [ref] $iosp
                [VOID] $execcmd.Parameters.Add($ioP[$_].Value)
            }
        }   

        $execcmd.CommandTimeout = $Timeout
        if($iexOnTheFly -ne ""){iex $iexOnTheFly}

        $exec = $execcmd.ExecuteNonQuery()
        if($ifclose){ 
            $specified_conn.close()
        }

        Add-Member -InputObject $exec -MemberType NoteProperty -Name SQLConn -Value $specified_conn
        Add-Member -InputObject $exec -MemberType NoteProperty -Name ioP -Value $ioP
        return (returnRefSuccess executeNonQuery executeNonQueryInvoked ([ref] $exec))
    }
    catch [exception] {return (returnHashError execError execNonQueryFailed)}
}


$nativeTyp2dbTyp = New-Object 'system.collections.generic.dictionary`2[[System.Reflection.TypeInfo], [System.Data.DbType]]'
$nativeTyp2dbLen = New-Object 'system.collections.generic.dictionary`2[[System.Reflection.TypeInfo], [int]]'
$dbTyp2nativeTyp = New-Object 'system.collections.generic.dictionary`2[[string], [System.Reflection.TypeInfo]]'
$nativeTyp2dbTyp.Add([int16], [System.Data.DbType]::Int16)
$nativeTyp2dbTyp.Add([uint16], [System.Data.DbType]::UInt16)
$nativeTyp2dbTyp.Add([int], [System.Data.DbType]::Int32)
$nativeTyp2dbTyp.Add([uint32], [System.Data.DbType]::UInt32)
$nativeTyp2dbTyp.Add([long], [System.Data.DbType]::Int64)
$nativeTyp2dbTyp.Add([uint64], [System.Data.DbType]::UInt64)
$nativeTyp2dbTyp.Add([float], [System.Data.DbType]::Single)
$nativeTyp2dbTyp.Add([double], [System.Data.DbType]::Double)
$nativeTyp2dbTyp.Add([decimal], [System.Data.DbType]::Decimal)
$nativeTyp2dbTyp.Add([bool], [System.Data.DbType]::Boolean)
$nativeTyp2dbTyp.Add([string], [System.Data.DbType]::String)
$nativeTyp2dbTyp.Add([char], [System.Data.DbType]::StringFixedLength)
$nativeTyp2dbTyp.Add([Guid], [System.Data.DbType]::Guid)
$nativeTyp2dbTyp.Add([DateTime], [System.Data.DbType]::DateTime)
$nativeTyp2dbTyp.Add([DateTimeOffset], [System.Data.DbType]::DateTimeOffset)
$nativeTyp2dbTyp.Add([byte[]], [System.Data.DbType]::Binary)
$nativeTyp2dbTyp.Add([System.Nullable[byte]], [System.Data.DbType]::Byte)
$nativeTyp2dbTyp.Add([System.Nullable[sbyte]], [System.Data.DbType]::SByte)
$nativeTyp2dbTyp.Add([System.Nullable[int16]], [System.Data.DbType]::Int16)
$nativeTyp2dbTyp.Add([System.Nullable[uint16]], [System.Data.DbType]::UInt16)
$nativeTyp2dbTyp.Add([System.Nullable[int]], [System.Data.DbType]::Int32)
$nativeTyp2dbTyp.Add([System.Nullable[uint32]], [System.Data.DbType]::UInt32)
$nativeTyp2dbTyp.Add([System.Nullable[long]], [System.Data.DbType]::Int64)
$nativeTyp2dbTyp.Add([System.Nullable[uint64]], [System.Data.DbType]::UInt64)
$nativeTyp2dbTyp.Add([System.Nullable[float]], [System.Data.DbType]::Single)
$nativeTyp2dbTyp.Add([System.Nullable[double]], [System.Data.DbType]::Double)
$nativeTyp2dbTyp.Add([System.Nullable[decimal]], [System.Data.DbType]::Decimal)
$nativeTyp2dbTyp.Add([System.Nullable[bool]], [System.Data.DbType]::Boolean)
$nativeTyp2dbTyp.Add([System.Nullable[char]], [System.Data.DbType]::StringFixedLength)
$nativeTyp2dbTyp.Add([System.Nullable[Guid]], [System.Data.DbType]::Guid)
$nativeTyp2dbTyp.Add([System.Nullable[DateTime]], [System.Data.DbType]::DateTime)
$nativeTyp2dbTyp.Add([System.Nullable[DateTimeOffset]], [System.Data.DbType]::DateTimeOffset)
$nativeTyp2dbTyp.Add([System.Data.DataTable], [System.Data.DbType]::Object)
#$nativeTyp2dbTyp.Add([data.datatable], [System.Data.SqlDbType]::Structured)
#$nativeTyp2dbTyp.Add([System.Data.Linq.Binary], [System.Data.DbType]::Binary)

$dbTyp2nativeTyp.Add("$("bigint", "not null", $null, $null)", [long])
$dbTyp2nativeTyp.Add("$("bigint", "null", $null, $null)", [System.Nullable[long]])
$dbTyp2nativeTyp.Add("$("bit", "not null", $null, $null)", [bool])
$dbTyp2nativeTyp.Add("$("bit", "null", $null, $null)", [System.Nullable[bool]])
$dbTyp2nativeTyp.Add("$("datetime", "not null", $null, $null)", [DateTime])
$dbTyp2nativeTyp.Add("$("datetime", "null", $null, $null)", [System.Nullable[DateTime]])
$dbTyp2nativeTyp.Add("$("decimal", "not null", $null, $null)",  [decimal])
$dbTyp2nativeTyp.Add("$("decimal", "null", $null, $null)",  [System.Nullable[decimal]])
$dbTyp2nativeTyp.Add("$("int", "not null", $null, $null)", [int])
$dbTyp2nativeTyp.Add("$("int", "null", $null, $null)", [System.Nullable[int]])
$dbTyp2nativeTyp.Add("$("nvarchar", "not null", $null, $null)", [string]) 
$dbTyp2nativeTyp.Add("$("nvarchar", "null", $null, $null)", [string])
$dbTyp2nativeTyp.Add("$("sql_variant", "not null", $null, $null)",[string])
$dbTyp2nativeTyp.Add("$("sql_variant", "null", $null, $null)", [string])
$dbTyp2nativeTyp.Add("$("tinyint", "not null", $null, $null)", [string])
$dbTyp2nativeTyp.Add("$("tinyint", "null", $null, $null)", [string])
$dbTyp2nativeTyp.Add("$("varchar", "not null", $null, $null)", [string])
$dbTyp2nativeTyp.Add("$("varchar", "null", $null, $null)", [string])

$nativeTyp2dbLen.Add([int16], 2)
$nativeTyp2dbLen.Add([uint16], 2)
$nativeTyp2dbLen.Add([int], 4)
$nativeTyp2dbLen.Add([uint32], 4)
$nativeTyp2dbLen.Add([long], 8)
$nativeTyp2dbLen.Add([uint64], 8)
$nativeTyp2dbLen.Add([float], 8)
$nativeTyp2dbLen.Add([double], 8)
$nativeTyp2dbLen.Add([decimal], 17)
$nativeTyp2dbLen.Add([bool], 1)
$nativeTyp2dbLen.Add([string], 4000)
$nativeTyp2dbLen.Add([char], -1)
$nativeTyp2dbLen.Add([Guid], 36)
$nativeTyp2dbLen.Add([DateTime], 8)
$nativeTyp2dbLen.Add([DateTimeOffset], 10)
$nativeTyp2dbLen.Add([byte[]], 4000)
$nativeTyp2dbLen.Add([System.Nullable[byte]], 1)
$nativeTyp2dbLen.Add([System.Nullable[sbyte]], 1)
$nativeTyp2dbLen.Add([System.Nullable[int16]], 2)
$nativeTyp2dbLen.Add([System.Nullable[uint16]], 2)
$nativeTyp2dbLen.Add([System.Nullable[int]], 4)
$nativeTyp2dbLen.Add([System.Nullable[uint32]], 4)
$nativeTyp2dbLen.Add([System.Nullable[long]], 8)
$nativeTyp2dbLen.Add([System.Nullable[uint64]], 8)
$nativeTyp2dbLen.Add([System.Nullable[float]], 8)
$nativeTyp2dbLen.Add([System.Nullable[double]], 8)
$nativeTyp2dbLen.Add([System.Nullable[decimal]], 17)
$nativeTyp2dbLen.Add([System.Nullable[bool]], 1)
$nativeTyp2dbLen.Add([System.Nullable[char]], 1)
$nativeTyp2dbLen.Add([System.Nullable[Guid]], 36)
$nativeTyp2dbLen.Add([System.Nullable[DateTime]], 8)
$nativeTyp2dbLen.Add([System.Nullable[DateTimeOffset]], 10)
$nativeTyp2dbLen.Add([System.Data.DataTable], -1)

$funcExp = "Get-MSSQLData", "Get-PassCred", "Exec-MSSQLData", "Get-MSSQLConn", "returnRefSuccess", "returnSuccess", 
    "returnHashError", "returnMsgError", "returnHashRefError", "Get-SqlCred"
    


$varExp = "nativeTyp2dbTyp", "nativeTyp2dbLen"

Export-ModuleMember -Function $($funcExp) -Variable $($varExp)




<#
Import-Module sqldata -Force -DisableNameChecking
Import-Module poshls -Force -DisableNameChecking
$a = Get-MSSQLData -sql "select @@servername" -IFCLOSE $false
$con = $a.returnValue.Value.SQLConn
$con.close()
$con.Credential = Get-SqlCred -username sa -password "/'],lp123"
$con.open()
$con.ChangeDatabase("tempdb")
$a = Get-MSSQLData -sql "select @@servername" -IFCLOSE $false `
    -connection $con
$a



















#>