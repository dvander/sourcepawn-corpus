	#include <sourcemod>
	
	#define BLOCKKILL_VERSION "1.3"
	new Handle:sm_blockkill_enabled;
	new Handle:sm_blockkill_notify;
	
	public Plugin:myinfo = 
	{
		name = "Block Kill",
		author = "Xuqe Noia & Sanya_Zol",
		description = "Blocks suicide commands",
		version = BLOCKKILL_VERSION,
		url = "http://LiquidBR.com"
	};
	
	public OnPluginStart()
	{
		CreateConVar( "sm_blockkill_version", BLOCKKILL_VERSION, "KillBlock Version", FCVAR_NOTIFY );
		sm_blockkill_enabled = CreateConVar("sm_blockkill_enabled", "1", "Enable or disable KillBlock; 0 - disabled, 1 - enabled");
		sm_blockkill_notify = CreateConVar("sm_blockkill_notify", "1", "Enable or disable KillBlock chat notify; 0 - disabled, 1 - enabled");
		AddCommandListener(BlockKill, "kill");
		AddCommandListener(BlockKill, "explode");
	}
	
	public Action:BlockKill(client, const String:command[], argc)
	{
		if (GetConVarInt(sm_blockkill_enabled) != 1) { return Plugin_Continue; }
		// don't forget to credit Sanya_Zol
		new flags = GetUserFlagBits(client);
		if(flags & ADMFLAG_GENERIC || flags & ADMFLAG_ROOT || flags & ADMFLAG_SLAY || flags & ADMFLAG_CHEATS) {
			// admins with one of this 4 flags constantly shouldn't be affected
			return Plugin_Continue;
		}
		if(GetConVarInt(sm_blockkill_notify)==1) {
			PrintToChat(client, "\x04[BlockKill]\x01 Suicide commands is blocked!");
		}
		return Plugin_Handled;
	}