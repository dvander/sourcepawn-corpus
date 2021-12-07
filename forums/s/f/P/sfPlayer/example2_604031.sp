// 2nd example for the config extension

#include <sourcemod>
#include <config>

public Plugin:myinfo = {
	name = "config example 2",
	author = "Player",
	description = "config example no2",
	version = "1.0.0",
	url = "http://www.player.to/"
};
 
public OnPluginStart() {
    new Handle:config = ConfigCreate();

    if (!ConfigReadFile(config)) {
        LogError("can't read config file");
        return;
    }

    decl String:prefix[20];
    ConfigLookupString(config, "say_prefix", prefix, sizeof(prefix));

    decl String:outputFormat[100];
    ConfigLookupString(config, "output", outputFormat, sizeof(outputFormat));

    decl String:localHost[25];
    // . separates setting names in a path
    ConfigLookupString(config, "localhost.host",localHost,sizeof(localHost));

    new localPort = ConfigLookupInt(config, "localhost.port");

	PrintToServer("result: %s %s %s %d", prefix, outputFormat, localHost, localPort);

    // get parent setting containing the remote host groups
    new Handle:parent = ConfigLookup(config, "remotehosts");

    // get amount of children
    new length = ConfigSettingLength(parent);

    // iterate through children
    for (new i=0; i<length; i++) {
        // retrieve child setting (the group with remoteHost's host+port)
        new Handle:child = ConfigSettingGetElement(parent, i);

        // retrieve child "host" from the group
        new Handle:childHost = ConfigSettingGetMember(child, "host");
        // store host in a string
        decl String:remoteHost[25];
        ConfigSettingGetString(childHost, remoteHost, sizeof(remoteHost));

        // retrieve child "port" from the group
        new Handle:childPort = ConfigSettingGetMember(child, "port");
        // get the port
        new remotePort = ConfigSettingGetInt(childPort);
        
       	PrintToServer("result c: %s %d", remoteHost, remotePort);

        // [...] do something with remoteHost+remotePort
        // don't close setting handles, only config handles!
    }

     // close the config handle
    CloseHandle(config);
}
