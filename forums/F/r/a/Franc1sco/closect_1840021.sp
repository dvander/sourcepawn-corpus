#pragma semicolon 1
#include <sourcemod>

new Handle:g_hEnabled = INVALID_HANDLE;

public OnPluginStart()
{
    g_hEnabled = CreateConVar("cct_enable", "0");
    
    RegAdminCmd("sm_closect", Command_CloseCT, ADMFLAG_ROOT);

    RegConsoleCmd("jointeam", Join);
}

public Action: Command_CloseCT(userid, args)
{
    if(GetConVarInt(g_hEnabled) == 1)
    {
        SetConVarInt(g_hEnabled, 0);
        PrintToChatAll("[SM] CT team is no longer closed by an admin");
    }
    else
    {
        SetConVarInt(g_hEnabled, 1);
        PrintToChatAll("[SM] CT team is now closed by an admin");
    }
}  

public Action:Join(client, args)
{
  decl String:team[2]; GetCmdArg(1, team, sizeof(team));

  new teamnumber = StringToInt(team);


  if (GetConVarInt(g_hEnabled) == 1 && teamnumber == 3 && GetUserAdmin(client) == INVALID_ADMIN_ID)
  {
      PrintToChat(client, "[SM] CT team is closed by an admin, you cannot join this team!");
      return Plugin_Handled;
  }
  return Plugin_Continue;

} 