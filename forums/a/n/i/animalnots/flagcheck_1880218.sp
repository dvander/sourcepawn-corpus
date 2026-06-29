#include <sourcemod>
#define NAME "FLAGCHECK"
#define VERSION "1.0"

public Plugin:myinfo = {
	name = NAME,
	author = "Chuck Norris",
	version = VERSION,
	description = "Checks a client for flags",
	url = "http://www.sourcemod.net"
};

public OnPluginStart() {
	// nothing to do
}

public OnClientPostAdminCheck(client) {
	/* a client connected
	o = ADMFLAG_CUSTOM1
	p = ADMFLAG_CUSTOM2
	q = ADMFLAG_CUSTOM3
	r = ADMFLAG_CUSTOM4
	s = ADMFLAG_CUSTOM5
	t = ADMFLAG_CUSTOM6
	*/
	
	//get & check his flags
	new flags = GetUserFlagBits(client);
	if (flags & ADMFLAG_CUSTOM1 || flags & ADMFLAG_ROOT)
	{
		// Yes, he has a flag
	}
}