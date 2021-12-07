public Plugin myinfo = {
	name = "No Graffiti",
	author = "SM9(); (xCoderx)",
	description = "Prevents players using graffiti",
	version = "0.1",
	url = "https://www.fragdeluxe.com"
};

public Action OnPlayerRunCmd(int iClient) {
	SetEntPropFloat(iClient, Prop_Send, "m_flNextDecalTime", GetGameTime() + 999);
}