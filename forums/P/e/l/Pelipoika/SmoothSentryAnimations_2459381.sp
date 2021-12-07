#include <sdktools>

#pragma newdecls required

enum
{
	SENTRY_STATE_INACTIVE = 0,
	SENTRY_STATE_SEARCHING,
	SENTRY_STATE_ATTACKING,
	SENTRY_STATE_UPGRADING,

	SENTRY_NUM_STATES,
};

public Plugin myinfo = 
{
	name = "[TF2] Smooth Sentry Construct & Upgrade Animations",
	author = "Pelipoika",
	description = "",
	version = "1.0",
	url = "http://www.sourcemod.net/plugins.php?author=Pelipoika&search=1"
};

public void OnGameFrame()
{
	int iBuilding = -1;
	while((iBuilding = FindEntityByClassname(iBuilding, "obj_sentrygun")) != -1)
	{
		bool bClientSideAnim = !!GetEntProp(iBuilding, Prop_Send, "m_bClientSideAnimation");
		int iState = GetEntProp(iBuilding, Prop_Send, "m_iState");
		
	//	PrintToServer("bClientSideAnim %i iState %i", bClientSideAnim, iState);
		
		if((iState == SENTRY_STATE_UPGRADING || iState == SENTRY_STATE_INACTIVE) && !bClientSideAnim)
		{
			SetEntProp(iBuilding, Prop_Send, "m_bClientSideAnimation", true);
		}
		else if(iState != SENTRY_STATE_UPGRADING && iState != SENTRY_STATE_INACTIVE && bClientSideAnim)
		{
			SetEntProp(iBuilding, Prop_Send, "m_bClientSideAnimation", false);
		}
	}
}
