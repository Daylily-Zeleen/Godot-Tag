# NOTE: This file is generated, any modify maybe discard.
class_name DTagDef


## Tag without domain
const TagWithoutDomain = &"TagWithoutDomain"

## Tag without domain
const TagWithoutDomain1 = &"TagWithoutDomain1"


## Desc
const MainDomain = {
	DOMAIN_NAME = &"MainDomain",
	## Desc
	Tag1 = &"Redirect.To.New.Tag",
	## Desc
	Domain = {
		DOMAIN_NAME = &"Redirect.To.New.Domain",
		## Will be auto redirect to "Redirect.To.New.Domain.Tag2"
		Tag2 = &"Redirect.To.New.Domain.Tag2",
		## Will be auto redirect to "Redirect.To.New.Domain.Tag3"
		Tag3 = &"Redirect.To.New.Domain.Tag3",
	},
}

## Sample redirect domain.
const Redirect = {
	DOMAIN_NAME = &"Redirect",
	To = {
		DOMAIN_NAME = &"Redirect.To",
		New = {
			DOMAIN_NAME = &"Redirect.To.New",
				Tag = &"Redirect.To.New.Tag",
				Domain = {
					DOMAIN_NAME = &"Redirect.To.New.Domain",
							Tag1 = &"Redirect.To.New.Domain.Tag1",
							Tag2 = &"Redirect.To.New.Domain.Tag2",
							Tag3 = &"Redirect.To.New.Domain.Tag3",
				},
		},
	},
}


# ===== Redirect map. =====
const _REDIRECT_NAP: Dictionary[StringName, StringName] = {
	&"MainDomain.Tag1" : &"Redirect.To.New.Tag",
	&"MainDomain.Domain" : &"Redirect.To.New.Domain",
	&"MainDomain.Domain.Tag2" : &"Redirect.To.New.Domain.Tag2",
	&"MainDomain.Domain.Tag3" : &"Redirect.To.New.Domain.Tag3",
}
