local list = {}

list.deprecated = {
	[":connect"] = "Deprecated function connection", [":Remove"] = ":Remove()", 
	[":remove"] = ":remove()", ["Draggable"] = "Deprecated property 'Draggable'", 
	[":clone"] = ":Deprecated clone", [":findFirstChild"] = "Deprecated FindFirstChild()",
	[":destroy"] = "Deprecated Destroy()", [":isA"] = "Deprecated IsA()",
	[":getChildren"] = "Deprecated GetChildren()", [":children"] = "Deprecated function 'children()'",
	[":isDescendantOf"] = "Deprecated IsDescendantOf()", [".childAdded"] = "Deprecated signal 'childAdded'",
	["className"] = "Deprecated property 'className'", ["archivable"] = "Deprecated property 'archivable'"
}

return list
