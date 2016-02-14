$var_pool = @{
    PATTLE64 = @(
    '0','1','2','3','4','5','6','7','8','9',
    'a','b','c','d','e','f','g','h','i','j',
    'k','l','m','n','o','p','q','r','s','t',
    'u','v','w','x','y','z','A','B','C','D',
    'E','F','G','H','I','J','K','L','M','N',
    'O','P','Q','R','S','T','U','V','W','X',
    'Y','Z','+','-')
}

function genP64Dict{
    $PATTLE64 = $var_pool["PATTLE64"]

    $pattle64Dict = New-Object "System.Collections.Generic.Dictionary``2[[Char],[Int]]"

    $PATTLE64 | %{
        $pattle64Dict.Add(
            $_
            , $pattle64Dict.Count
        )
    }
    return $pattle64Dict
}

function FourByteToThreeByte{
    param(
        $input_Data
        , [ref] $this_pattle64Dict
    )
    $pattleTempList = New-Object "System.Collections.Generic.List`[[int]]"
    $result = New-Object "System.Collections.Generic.List`[[byte]]"

    $input_Data.ToCharArray() | %{
        if ($this_pattle64Dict.Value.ContainsKey($_)){
            $pattleTempList.Add($this_pattle64Dict.Value[$_])
        }
    }

    for ($i = 0; $i -le $pattleTempList.Count - 1; $i += 4){
        $temp = 0
        $count = 1;

        switch ($pattleTempList.Count - $i){
            0{ break; }
            1{
                $temp = $pattleTempList[$i];
                break;
            }
            2{
                $temp = $pattleTempList[$i] + $pattleTempList[$i + 1] * 64;
                break;
            }
            3{
                $temp = $pattleTempList[$i] + $pattleTempList[$i + 1] * 64 + $pattleTempList[$i + 2] * 4096;
                break;
            }
            default{
                $temp = $pattleTempList[$i] + $pattleTempList[$i + 1] * 64 + $pattleTempList[$i + 2] * 4096 + $pattleTempList[$i + 3] * 262144;
                break;
            }
        }
        
        while ($temp -ge 256){
            $result.Add([byte][system.Convert]::ToChar([int] $temp % 256))
            $temp = ($temp - ($temp % 256)) / 256;
                $count++;
        }

        $result.Add([byte][system.Convert]::ToChar([int] $temp));

        while ($count -lt 3){
            if ($count + 1 -ge $input_Data.Length - $i) {
                break;
            }
            $result.Add([system.Convert]::ToByte(0));
            $count++;
        }

    }
    return $result.ToArray()
}

function ThreeByteToFourByte{
    param(
        $input_Data
        #, [ref] $this_pattle64Dict
    )
    if($input_Data -is [string]){
        $b_input_Data = [System.Text.Encoding]::Default.GetBytes($input_Data)
    } elseif ($input_Data -is [object[]]){
        $b_input_Data = $input_Data
    } else {
        throw "Error input_data!"
    }
    $PATTLE64 = $var_pool["PATTLE64"]
    $result = ""

    for ($i = 0; $i -le $b_input_Data.Length - 1; $i += 3){
        $temp = 0 
        $count = 1;

        switch ($b_input_Data.Length - $i){
            0{ break; }
            1{
                $temp = [inT] $b_input_Data[$i]
                break;
            }
            2{
                $temp = ([int] $b_input_Data[$i]) + ([int] $b_input_Data[$i + 1]) * 256;
                break;
            }
            default{
                $temp = ([int] $b_input_Data[$i]) + ([int] $b_input_Data[$i + 1]) * 256 + ([int] $b_input_Data[$i + 2]) * 65536;
                break;
            }
        }

        while ($temp -ge 64) {
            $result += $PATTLE64[$temp % 64];
            $temp = ($temp - ($temp % 64)) / 64;
                $count++;
        }

        $result += $PATTLE64[$temp];

        while ($count -lt 4){
            if ($count -ge $b_input_Data.Length - $i + 1) {break}
            $result += $PATTLE64[0];
            $count++;
        }
    }
    return $result
}

function _Decode{
    param(
        $bword
        , $key
        , $iv
    )
    try {
        $bkey = [text.Encoding]::Default.GetBytes($key)
        $biv = [text.Encoding]::Default.GetBytes($iv)

        $rij = New-Object System.Security.Cryptography.RijndaelManaged
        $stmout = New-Object System.IO.MemoryStream
        $stmcrypt = New-Object System.Security.Cryptography.CryptoStream(
            $stmout, 
            $rij.CreateDecryptor($bkey, $biv), 
            [System.Security.Cryptography.CryptoStreamMode]::Write
        )

        $stmcrypt.Write($bword, 0, $bword.Length);
        $stmcrypt.FlushFinalBlock();

        $result = $stmout.ToArray();
    } catch {
        $result = $null;
    }

    return $(if($result -eq $null){$null}
        else { [System.Text.Encoding]::Default.GetString($result) })
}

function _Encode{
    param(
        $bword
        , $key = $null
        , $iv  = $null
    )
    try{

        $rijm = New-Object System.Security.Cryptography.RijndaelManaged
        $rijm.GenerateKey()
        $rijm.GenerateIV()
        if($key -ne $null){
            $bkey = switch($key.gettype().name){"string"{[text.Encoding]::Default.GetBytes($key)} default {$rijm.Key}}
        } else {$key = $rijm.Key}

        if($iv -ne $null){
            $biv =  switch($iv.gettype().name) {"string"{[text.Encoding]::Default.GetBytes($iv)} default  {$rijm.IV}}   #[text.Encoding]::Default.GetBytes($iv);
        } else {$iv = $rijm.IV}

        $rij = New-Object System.Security.Cryptography.RijndaelManaged
        $stmout = New-Object System.IO.MemoryStream
        $stmcrypt = New-Object System.Security.Cryptography.CryptoStream(
            $stmout, 
            $rij.CreateEncryptor($bkey, $biv), 
            [System.Security.Cryptography.CryptoStreamMode]::Write
        )
        $stmcrypt.Write($bword, 0, $bword.Length);
        $stmcrypt.FlushFinalBlock();
        $bresult = $stmout.ToArray();

        return $bresult
    } catch {
        return $null
    }
}

function _DecodeProject{
    param(
        $solutionFolder = "d:\MISP\MIS"
        , $xmlfilename = "Environment.xml"
    )
    $pattle64Dict = genP64Dict

    $cs = GC (dir "$($solutionFolder -replace "(?<!\\)$", "\")SDK\WPEnvironment.cs").FullName | Out-String
    $key = $($cs -match "static\s+string\s+key = `"(?<key>[^`"]+)`"" > $null; $Matches.key)
    $iv = $($cs -match "static\s+string\s+iv = `"(?<key>[^`"]+)`"" > $null; $Matches.key)

    $xml = [xml] $(GC (dir "$($solutionFolder -replace "(?<!\\)$", "\")WEB\$xmlfilename").FullName | Out-String)
    $cstrs = $xml.GetElementsByTagName("ConnectionStrings")
    0..($cstrs.Count - 1) | %{
        $con = $cstrs.Item($_)
        Write-Host $con.ParentNode.Name -ForegroundColor Yellow
        $con.ChildNodes | %{
            Write-Host ("`t" + $_.name) -ForegroundColor Cyan
            Write-Host ("`t`t" + (_Decode $(FourByteToThreeByte $_.connectionString $([ref] $pattle64Dict)) $key $iv)) -ForegroundColor Red
        }
    }
}

function _EncodeProject{
    param(
        $solutionFolder = "d:\MISP\MIS"
        , $xmlfilename = "Environment.xml"
        , $env_name = $null #"開發環境"
        , $constr_name = $null
        , $constr_val = "Data Source=orcl12c.oracle.ttc;Initial Catalog=MISPDB_1;User ID=mtadm;Password=mtadm456"
    )
    $cs = GC (dir "$($solutionFolder -replace "(?<!\\)$", "\")SDK\WPEnvironment.cs").FullName | Out-String
    $key = $($cs -match "static\s+string\s+key = `"(?<key>[^`"]+)`"" > $null; $Matches.key)
    $iv = $($cs -match "static\s+string\s+iv = `"(?<key>[^`"]+)`"" > $null; $Matches.key)

    $xmlfile = (dir "$($solutionFolder -replace "(?<!\\)$", "\")WEB\$xmlfilename").FullName
    $xml = [xml] $(GC $xmlfile | Out-String)
    $cstrs = $xml.GetElementsByTagName("ConnectionStrings")

    0..($cstrs.Count - 1) | %{
        $con = $cstrs.Item($_)
        $envnm = $con.ParentNode.Name 
        if(($env_nm -eq $null) -or ($envnm -eq $env_name)){    
            Write-Host $con.ParentNode.Name -ForegroundColor Yellow
            0..($con.ChildNodes.Count - 1) | %{
                if(($constr_name -eq $null) -or ($constr_name -eq $_.name)){
                    Write-Host ("`t" + $con.ChildNodes[$_].name) -ForegroundColor Cyan
                    Write-Host ("`t`t" + $con.ChildNodes[$_].connectionString + " => ") -ForegroundColor White
                    $con.ChildNodes[$_].connectionString = ThreeByteToFourByte (_Encode ([System.Text.Encoding]::Default.GetBytes($constr_val)) $key $iv)
                    Write-Host ("`t`t" + $con.ChildNodes[$_].connectionString) -ForegroundColor Red
                }
            }
        }
    }
    #$xml.Save($xmlfile)
    $xml.Save("$($solutionFolder -replace "(?<!\\)$", "\")WEB\$xmlfilename")
}





#_DecodeProject -xmlfilename Environment.xml




$funcExp = "genP64Dict", "FourByteToThreeByte", "ThreeByteToFourByte", "_Decode", "_Encode"
$varExp = @("var_pool")

Export-ModuleMember -Function $($funcExp) -Variable $($varExp)