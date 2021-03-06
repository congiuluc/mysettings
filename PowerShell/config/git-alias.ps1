############################################
############# Creating Array of all commands

$myCommands = New-Object System.Collections.ArrayList

function AddGitAlias([string] $alias,
    [string] $commandText,
    [string] $command,
    [string] $description){
    $myCommands.Add([pscustomobject] @{
        alias="$alias";
        commandText="$commandText";
        command=$command;
        description=$description}) `
    > $null
}


function git-execCommand([string] $command, [string] $description){
    if($description){
        Write-Info $description
    }
    Write-Command $command
    iex $command
}

############################################
########### Defining commands ############

$gitStatusCmd =  ' git status --short'
function git-status {
    git-execCommand $gitStatusCmd
}
AddGitAlias "ggst" "$gitStatusCmd" "git-status"


$gitDiffCmd = 'git diff'
function git-diff {
    Write-Info "git diff"
    iex $gitDiffCmd
    git diff --staged
}
AddGitAlias "ggdf" $gitDiffCmd "git-diff" "show changes in files"


$gitBranchNameCmd = ' git rev-parse --abbrev-ref HEAD '
function git-branchName { iex $gitBranchNameCmd }

$gitBranchAllCmd = ' git branch -a'
function git-branchAll { iex $gitBranchAllCmd }

$gitAddCmd = 'git add -A'
$gitCommitCmd = 'git commit -m "{0}"'
$gitAddAndCommitDesc = "Adding all unstaged files to stage,  Commiting staged files... "
function git-commit ([string] $message){
    if(!$message){
        Write-Err "Please provide a message for the commit !!!"
        return
    }
    git-execCommand $gitAddCmd $gitAddAndCommitDesc
    git-execCommand ($gitCommitCmd -f $message)
}
AddGitAlias "ggcommit" $gitCommitCmd  "git-commit" $gitAddAndCommitDesc


$gitResetCmd = 'git reset HEAD --hard'
$gitResetDesc =  "Unstaging all staged changes "
Function git-reset {
    git-execCommand $gitResetCmd $gitResetDesc
}
AddGitAlias "ggreset" $gitResetCmd "git-reset" $gitResetDesc

#######################################
#####  CHECKOUT

$gitCheckoutCmd = 'git checkout {0}'
$gitCheckoutDesc = "Switching to branch {0}"
function git-checkout([string] $branchName) {
    IF(!$branchName){
        $branchName = git-branchName
    }
    git-execCommand ($gitCheckoutCmd -f $branchName) ($gitCheckoutDesc -f $branchName)
    git-pull
}
AddGitAlias "ggch"  $gitCheckoutCmd  "git-checkout" $gitCheckoutDesc


function git-checkoutStar {
    git-checkout "*"
}
AddGitAlias "ggcs"  $gitCheckoutCmd  "git-checkoutStar" $gitCheckoutDesc


function git-checkoutWork {
    git-checkout "work"
}
AddGitAlias "ggwork" $gitCheckoutCmd "git-checkoutWork" $gitCheckoutDesc


function git-checkoutMaster {
    git-checkout "master"
}
AddGitAlias "ggmaster" $gitCheckoutCmd "git-checkoutMaster" $gitCheckoutDesc

################################################

$gitCleanCmd = 'git clean -fd'
$gitCleanDescription =  "Cleaning all untracked changes in files / directories / ignored."
function git-clean {
    git-execCommand $gitCleanCmd $gitCleanDescription
}
AddGitAlias "ggcln" $gitCleanCmd "git-clean" $gitCleanDescription


$gitCleanUSyncCmd = 'git clean -fd .\Source\Application.Web\uSync\ '
$gitCheckoutUSyncCmd = 'git checkout .\Source\Application.Web\uSync\* '
$gitCleanDescription =  "Cleaning all untracked changes in files / directories / ignored."
function git-cleanUSync {
    git-execCommand $gitCleanUSyncCmd
    git-execCommand $gitCheckoutUSyncCmd
}
AddGitAlias "ggcleanusync" ($gitCleanUSyncCmd + $gitCheckoutUSyncCmd) "git-cleanUSync" $gitCleanDescription


$gitRevertAllDesc = "Reverting all changes in current working directory (staged, unstaged, tracked, untracked, ignored)"
function git-revertAll {
    param ([switch] $clean)

    Write-Info $gitRevertAllDesc
    git-reset
    git-checkout
    if($clean){
        git-clean
    }
}
AddGitAlias "ggrevert" "$gitResetCmd ; $gitCheckoutStarCmd ; $gitCleanCmd " "git-revertAll" $gitRevertAllDesc


$gitUndoLastCommitCmd = "git reset HEAD^"
$gitUndoLastCommitDesc = "Undoing last commit, moving HEAD to previous commit."
function git-undoLastCommit {
    git-execCommand $gitUndoLastCommitCmd $gitUndoLastCommitDesc
}
AddGitAlias "ggundo" $gitUndoLastCommitCmd  "git-undoLastCommit" $gitUndoLastCommitDesc

#
# http://stackoverflow.com/questions/6934752/combining-multiple-commits-before-pushing-in-git
$gitSquashCmd = "git rebase -i origin/{0}"
function git-squash {
    $currentBranch = git-branchName
    git-execCommand ($gitSquashCmd -f $currentBranch )
}


# http://stackoverflow.com/questions/1274057/how-to-make-git-forget-about-a-file-that-was-tracked-but-is-now-in-gitignore
$gitForgetIgnoredCmd = "git rm --cached {0} -r"
function git-forget([string] $fileName) {
    if(!$fileName){
        Write-Err "Please provide a file to forget about!!"
        return
    }
    git-execCommand ($gitForgetIgnoredCmd -f $fileName )
}
AddGitAlias "ggforget" $gitForgetIgnoredCmd  "git-forget" $gitForgetIgnoredCmd


$gitPushCmd = "git push origin {0}"
$gitPushDesc =  "Pushing changes from current branch to origin."
function git-push ([string] $branchName) {
    IF(!$branchName){
        $branchName = git-branchName
    }
    git-execCommand ($gitPushCmd -f $branchName) $gitPushDesc
	git-pushTags $branchName
}
AddGitAlias "ggph" $gitPushCmd  "git-push" $gitPushDesc


$gitPullCmd = "git pull origin {0}"
$gitPullDesc =  "Pulling changes from origin to current branch. This will update code from origin. Eqivalent to SVN update."
function git-pull ([string] $branchName) {
    IF(!$branchName){
        $branchName = git-branchName
    }
    git-execCommand ($gitPullCmd -f $branchName) $gitPullDesc
    git-execCommand "git submodule update --recursive --remote"
    git-pullTags $branchName
}
AddGitAlias "ggpl" $gitPullCmd  "git-pull" $gitPullDesc


$gitSaveDesc = "Save current work with generic message"
Function git-save {
    $time = Get-Date -format u
    git-commit "Save at $time"
}
AddGitAlias "ggsave" $gitCommitCmd "git-save" $gitSaveDesc


$gitSavePushDesc = "Save current changes and push them into otigin"
Function git-savePush {
    git-save
    git-push
}
AddGitAlias "ggsave" $gitCommitCmd "git-savePush" $gitSavePushDesc


$gitMergeDesc = "Merge branch '{0}' to current branch '{1}'"
$gitMergeCmd = "git merge {0}"
function git-merge([string] $mergeFromBranch){
    if(! $mergeFromBranch){
        Write-Err "Please provide source branch for merge"
        return
    }
    git-execCommand ($gitMergeCmd -f $mergeFromBranch)
    git-push
}
AddGitAlias "ggmerge" $gitMergeCmd "git-merge" $gitMergeDesc


$gitGrepCmd = "git grep --ignore-case --line-number -B {0} -A {1} '{2}' -- './{3}' "
function git-grep () {
    param(
        [string] $pattern,
        [int] $before = 0,
        [int] $after = 0,
        [string] $include = "*",
        [string] $exclude = $null,
        [switch] $includeRB
    )
    $gitGrepCmdResult = $gitGrepCmd
    if(! $includeRB){
        $exclude = "*.css,rbdotcom*.js,dist/**"
    }

    if($exclude){
        "$exclude".Split("{,}") | % { $gitGrepCmdResult += (" ':(exclude)*/{0}'" -f $_ ) }
    }

    git-execCommand ($gitGrepCmdResult -f $before, $after, $pattern, $include )
}
AddGitAlias "ggfind" $gitGrepCmd "git-grep"  "search for a string in repository"



$gitRefreshDesc = "Refresh master and work branches by pulling all changes from them"
Function git-refresh {
    $currentBranch = git-branchName
    git-checkoutMaster
    git-checkoutWork
    git-checkout $currentBranch
}
AddGitAlias "ggrefresh" $gitPushCmd "git-refresh" $gitResetDesc




# git log man : https://git-scm.com/docs/git-log
# Format options :
# %d: ref names, like the --decorate option of git-log[1] - branch names
# %ar: author date, relative
# %h: abbreviated commit hash
# %s: subject - commit message
# %an: author name - of a commit
$gitLogGraphCmd = "git log --graph " +
    "--abbrev-commit " +
    "--decorate "+
    "--format=format:'" +
        "%C(bold yellow)%d%C(reset) " +       # branch name
        "%n      " +                          # new line
        "%C(bold green)(%ar)%C(reset) " +     # date of commit
        "%C(dim white) [%an]%C(reset) - " +   # author name
        "%C(white)%s%C(reset) " +             # commit message
        "%C(bold blue)[%h]%C(reset)" +        # short hash of commit
        "' --all" +
        " --since='{0}'"
$gitLogGraphDesc = "Getting branch tree "
function git-logGraph{
    param($fromLastDays = 14)

    $sinceDate = "{0:yyyy-MM-dd}" -f (Get-Date).AddDays(-1 * $fromLastDays)
    git-execCommand ($gitLogGraphCmd -f $sinceDate) $gitLogGraphDesc
}
AddGitAlias "ggbranchlog" $gitLogGraphCmd "git-logGraph" $gitLogGraphDesc


$gitHistoryCmd = "git log " +
    " --pretty=format:'" +
    "%C(bold blue)%h%C(reset)" +        # short hash of commit
    "%C(bold yellow)%d%C(reset) \\ " +
    "%C(dim white) [%an]%C(reset) - " +   # author name
    "%C(white)%s%C(reset) " +             # commit message
    "' --since='{0}'" +
    " --decorate "
$gitHistoryDesc =  "Getting commit history of current branch."
Function git-history{
    param($sinceDays = 30)

    $sinceDate = "{0:yyyy-MM-dd}" -f (Get-Date).AddDays(-1 * $sinceDays)
    git-execCommand ($gitHistoryCmd -f $sinceDate) $gitHistoryDesc
}
AddGitAlias "gghist" $gitHistoryCmd "git-history" $gitHistoryDesc


$gitTortoiseResolveCmd =  "TortoiseGitProc.exe /command:resolve"
Function git-resolve{
    Invoke-Expression "$gitTortoiseResolveCmd"
}
AddGitAlias "ggresolve" $gitTortoiseResolveCmd "git-resolve"


$gitTortoiseStatusCmd =  "TortoiseGitProc.exe /command:repostatus"
Function git-tgStatus{
    Invoke-Expression "$gitTortoiseStatusCmd"
}
AddGitAlias "ggvst" $gitTortoiseStatusCmd "git-tgStatus"


#################################################################################
################################# BLOG Scripts  #################################
#################################################################################

Function git-GetAllRemoteBranches {
    iex "git branch -r"                                <# get all remote branches #> `
        | % { $_ -Match "origin\/(?'name'\S+)" }       <# select only names of the branches #> `
        | %{ Out-Null; $matches['name'] }              <# write does names #>
}

Function git-CheckoutAllBranches {
    git-GetAllRemoteBranches `
        | % { iex "git checkout $_" }                  <# execute ' git checkout <branch>' #>
}

Function git-MergeMasterToAll {
    git-GetAllRemoteBranches `
        | % { iex "git checkout $_";       <# checkout branch that will be merged with master #> `
            iex "git merge master";        <# merge master branch into branch #> `
            iex "git push origin $_"; }    <# push merge into origin #>

    git-checkoutMaster
}

$gitRefreshAllDesc = "Refresh master and work branches by pulling all changes from them"
Function git-refreshAll {
    git-GetAllRemoteBranches | % { git-checkout $_ }
    git-checkoutMaster
}
AddGitAlias "ggrefreshAll" $gitPushCmd "git-refresh" $gitResetDesc


$gitPushTagsCmd = "git push origin {0} --tags"
$gitPushTagsDesc = "Pushes all local tags to origin"
Function git-pushTags([string] $branchName) {
	IF(!$branchName){
        $branchName = git-branchName
    }
    git-execCommand ($gitPushTagsCmd -f $branchName)
}
AddGitAlias "ggphtags" $gitPushTagsCmd "git-pushTags" $gitPushTagsDesc


$gitPullTagsCmd = "git pull origin {0} --tags"
$gitPullTagsDesc = "Pulls all local tags from origin"
Function git-pullTags([string] $branchName) {
    IF(!$branchName){
        $branchName = git-branchName
    }
    git-execCommand ($gitPullTagsCmd -f $branchName)
}
AddGitAlias "ggpltags" $gitPullTagsCmd "git-pullTags" $gitPullTagsDesc


$gitCreateTagCmd = "git tag -a '{0}' -m '{1}'"
$gitCreateTagDesc = "Create tag on current branch"
Function git-createTag {
    param($tagName, $tagDescription)
    git-execCommand ($gitCreateTagCmd -f "$tagName", "$tagDescription" )
}
AddGitAlias "ggctag" $gitCreateTagCmd "git-createTag" $gitCreateTagDesc


$gitPushWorkToMasterCmd = 'git push origin work:master '
Function git-pushToMasterAndTag{
    param($tagName, $tagDescription)

    git-execCommand $gitPushWorkToMasterCmd
    git-createTag $tagName $tagDescription
    git-pushTags
}
AddGitAlias "ggpushwork2master" $gitPushWorkToMasterCmd "git-pushToMasterAndTag"


# Help function
function MyGitHelp([string] $filter){
    Write-Info "My git commands"
    $filteredCommands = $myCommands

    if($filter){
        $likeFilter =  "*$filter*"
        $filteredCommands = $filteredCommands | Where {
            ($_.alias -like $likeFilter) `
            -or ($_.commandText -like $likeFilter) `
            -or ($_.description -like $likeFilter)
        }
    }

    $filteredCommands `
        | Sort-Object Alias `
        | ForEach {
        "`t" + $_.alias +
        "`t- " + $_.description +
        "`n`t`t" + $_.commandText +
        "`n"}
}
AddGitAlias "gghelp" "Displays this help text" "MyGitHelp"


# Setting Aliases
$myCommands | ForEach { Set-Alias -Name $_.alias -Value $_.command }


