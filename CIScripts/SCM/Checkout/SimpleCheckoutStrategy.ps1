using module ".\CheckoutStrategy.psm1"
. $PSScriptRoot\..\Repository\Repo.ps1
. $PSScriptRoot\..\..\Common\DeferExcept.ps1

class SimpleCheckoutStrategy : CheckoutStrategy {
    Checkout([System.Collections.Hashtable] $Repos) {
        $Repos.Values.ForEach({
            $_.Clone()
        })
    }
}
