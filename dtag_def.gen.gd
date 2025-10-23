# NOTE: This file is generated, any modify maybe discard.
class_name DTagDef


## Desc
const MainDomain = {
	DOMAIN_NAME = &"MainDomain",
	## Desc
	Tag1 = &"Redirect.To.New.Tag",
	## Desc
	Domain = {
		DOMAIN_NAME = &"Redirect.To.New.Domain",
		## Desc
		Tag2 = &"Redirect.To.New.Domain.Tag2",
		## Desc
		Tag3 = &"Redirect.To.New.Domain.Tag3",
	},
}


const _REDIRECT_NAP: Dictionary[StringName, StringName] = {
	&"MainDomain.Tag1" : &"Redirect.To.New.Tag",
}
