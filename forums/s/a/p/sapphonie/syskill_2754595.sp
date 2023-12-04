#include <sourcemod>
#include <system2>

public Plugin myinfo =
{
    name             =  "SysKill",
    author           =  "steph&nie",
    description      =  "Leverage System2 extension to kill the running srcds instance with linux's <kill> command",
    version          =  "0.0.1",
    url              =  "https://sappho.io"
}

public void OnPluginStart()
{
    RegServerCmd("sm_syskill", syskill, "<sm_syskill> <optional signal to send>\nkill this server's process id with system2_execute");
}

Action syskill(int args)
{
    // all of our args
    char killsig[10];

    GetCmdArg(1, killsig, sizeof(killsig));

    // our full cmd
    char killcmd[64];

    // idiot prevention
    if
    (
        StrContains(killsig, "#", false) != -1
        ||
        StrContains(killsig, "\"", false) != -1
        ||
        StrContains(killsig, "\'", false) != -1
        ||
        StrContains(killsig, "(", false) != -1
        ||
        StrContains(killsig, ")", false) != -1
        ||
        StrContains(killsig, "$", false) != -1
        ||
        StrContains(killsig, "&", false) != -1
        ||
        StrContains(killsig, "!", false) != -1
        ||
        StrContains(killsig, "?", false) != -1
        ||
        StrContains(killsig, "\b", false) != -1
        ||
        StrContains(killsig, "\n", false) != -1
        ||
        StrContains(killsig, "\r", false) != -1
    )
    {
        LogMessage("Write your own damn plugin if you want to cause trouble.");
        return Plugin_Handled;
    }

    ReplaceString(killsig, sizeof(killsig), "-", "", false);

    // no args? just do kill (which defaults to sigterm) then
    if (strlen(killsig) == 0)
    {
        Format(killcmd, sizeof(killcmd), "bash -c \"kill $PPID\"");
    }
    // args that are sane , put them in the right place
    else
    {
        Format(killcmd, sizeof(killcmd), "bash -c \"kill -%s $PPID\"", killsig);
    }

    // our final cmd
    LogMessage("%s", killcmd);

    // output if we dont end up actually killing the server (???)
    char dummy[1024];
    // $PPID = Parent Process ID
    // Works on my machine, not tested with anything other than bash
    System2_Execute(dummy, sizeof(dummy), killcmd);

    // how did we get here
    LogMessage("\n%s", dummy);
    return Plugin_Handled;
}
