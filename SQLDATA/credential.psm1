FUNCTION getHashWithDBRecord{
    PARAM(
        $tbl
        , $IDcol
        , $PWDcol
        , $IDvar = "@id"
        , $IDval
        , $pwdval
    )
    $getcredhash = Get-MSSQLData -sql "select $IDcol, $PWDcol from $tbl where $IDcol = @id and disabled = 0" -params @{
        id = $IDval
    }

    if($getcredhash.eval -eq 1){
        $row0 = $getcredhash.returnValue.Value.Tables[0].Rows[0]
        if($row0.m_pw -eq $pwdval){

            $bpwdval = [text.Encoding]::Unicode.GetBytes("$IDval@$(get-date -UFormat %Y-%m-%d)::$pwdval")

    
            $hash = ThreeByteToFourByte (_Encode $bpwdval) #. {param($id, $pwd) ([string] $id)[0] + ([string] $pwd)[0] } $row0."$IDcol" $row0."$PWDcol"
            return $hash
        } else {
            return $null
        }
    } else{
        return $null
    }
}











$funcExp = "getHashWithDBRecord", ""
$varExp = @()

Export-ModuleMember -Function $($funcExp) #-Variable $($varExp)