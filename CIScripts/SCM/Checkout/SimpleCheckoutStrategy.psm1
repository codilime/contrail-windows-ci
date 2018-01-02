using module ".\CheckoutStrategy.psm1"
using module "..\Repository\Repo.psm1"

. $PSScriptRoot\..\..\Common\DeferExcept.ps1

class SimpleCheckoutStrategy : CheckoutStrategy {
    Checkout([System.Collections.Hashtable] $Repos) {
        $Repos.Values.ForEach({
            Write-Host "Cloning branch $($_.Branch) from $($_.Url)" `
                       "into $($_.Dir)"
            git clone -q -b $_.Branch $_.Url $_.Dir
        })
    }
}
