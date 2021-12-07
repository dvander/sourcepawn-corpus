#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Kinsi"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <NestedStringMap>

#pragma newdecls required

public Plugin myinfo = {
	name = "NestedStringMapExample",
	author = PLUGIN_AUTHOR,
	description = "¯\\_(ツ)_//¯",
	version = PLUGIN_VERSION,
	url = "kinsi.me"
};

public void OnPluginStart() {
	//Create a nested stringmap object with enabled Iteration
	NestedStringMap topLevel = new NestedStringMap(true);
	
	//Child does not exist yet, will be created, written into the parent, and returned
	NestedStringMap child = topLevel.Child("firstChild");
	
	//Creates a sub-child in the created child, and sets the value of SomeKey to 1337
	child.Child("child1").SetValue("SomeKey", 1337);
	
	//Retrieves the set key from the created sub-child
	LogMessage("Read: %i", child.Child("child1").GetAndReturnValue("SomeKey"));
	
	//Creates some more sub-childs because why not. We'll disable Iteration for these, 
	//thus no ArrayLists will be created / maintained alongside of them.
	child.Child("child2", Iterator_Disable);
	child.Child("child3", Iterator_Disable);
	
	//iterating over the children of the first child-NestedStringMap
	NestedStringMapChildren NSMC;
	
	if(child.GetIterator(NSMC)) {
		for(int i = 0; i < NSMC.Length; i++) {
			char childName[255];
			
			NestedStringMap x = view_as<NestedStringMap>(NSMC.GetChild(i));
			
			x.GetName(childName, sizeof(childName));
			
			LogMessage("Child %i in NestedStringMap %i has name %s", i, child, childName);
		}
	}
	
	//Retrieve the sub-child from the child, go back to its parent again and close that.
	//Yes, it essentially is no different than "child.Close()";
	//Calling Close() will take care of also closing any possibly nested children
	child.Child("child3").Parent().Close();
	
	//Finally close the top level NestedStringMap
	topLevel.Close();
}