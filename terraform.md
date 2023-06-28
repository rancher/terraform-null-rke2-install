# Terraform Paradigms

This document explains the paradigms, tricks, tips, standards, and patterns used in the project.

## Attribute Order

Terraform does not have an opinion on what order attributes should be added to stanzas, but this project does.
If they occur, the following attributes must occur in the following order:

1. count
2. depends_on
3. for_each
4. source
5. version
6. triggers
7. everything else

The reason for this hierarchy is to prevent confusion and race conditions.
Maintainers and developers need to understand the order of operations for resources, which can have a complicated hierarchy.
Understanding the number of resources created or just an indication of the context for the resource (loop or noloop), is important.
This is so that you can easily reference the resource in dependent resources with the correct context.
Knowing where source and version of a module is important for maintaining multiple versions of the module.
In a limited set of objects it is necessary to provide a list of triggering objects,
  these are generally only referenced in null resources with destroy time provisioners,
  having them listed at the top is important since you will be referencing them throughout the resource.

## Dependency Management

Always explicitly state the dependencies of a module, even when they can be inferred by Terraform.
Most terraform modules have some hierarchy or order of operations.
Terraform assumes that all resources can be provisioned at the same time, unless some indicator is given.
Terraform is smart and if you reference a resource within another resource it can usually figure out the hierarchy, but this is inconsistent.
Many times Terraform has no indication that a resource has a dependency (most often with null resources),
 so you would need to provide a depends_on block anyways, this states to simply always provide one to help with development/maintenance.
Maintainers need to understand the order of operations when writing resources,
  so it is very handy to have the dependencies explicitly expressed at the top of the resource.
This looks somewhat messy and redundant in the code sometimes, but it often prevents race conditions and speeds up the development process.
This also leads to improvements as developers tend to plan concurrency efficiently.

## Three Uses of Module

The word "Module" is used in three contexts:

1. As a reference to an independent module published in a/the Terraform registry (Independent Module/XMod)
   - this reference is like a library call or an import statement (although it does have parameters)
   - the reference will be pulled in and compiled just before run time
   - versions of this module must be pinned to prevent inconsistent builds
2. As a reference to a local module (Local Module/LMod)
   - this reference is like a function call
   - it is integral (non separable) from the current module, but represents a segment of the overall goal
   - an example of this would be a security group and its rules
     - while rules can be added separately from the group and are their own resources they do not make a lot of sense to have in their own external module
     - it may be useful to separate out the rules from the group in logical form to keep top level (implementation) modules clean
3. As an implementation of resources (Implementation Module/IMod)
   - modules are generally considered a way to pull code into a terraform file, but eventually a "root" must be created
   - the "root module" or "impementation module" orchestrates a group of modules with the intent of actually provisioning resources (rather than just as a template or library)
   - using the git ops paradigm the implementation module should be considered the source of truth for the infrastructure
   - implementation modules usually have important data about the implementation, and should be treated accordingly
     - it is better to hard code values into this module than use variables, so maintainers can easily understand what is in place
     - secrets should be the only values passed as variables, Terraform should not handle secret data
     - beware, state files of these modules will usually need to be secured

## Count as a Feature Flag Not an Iterator

The count attribute should not be used to provision multiple resources, this can cause dependency chain issues and unnecessary resource deletion.
Resources generated with count are not set up in a specific order, however dependency chains are explicit.
This means that if a dependent resource discovers a change in a resource (by order number) it might be destroyed.
Consider if you have an unordered list of resources and you taint one,
  destroying and recreating the resource changes the order of resources in the list,
  dependent resources refer to the order in the list and get different values for the resource,
  the dependent resources are unable to alter the ids of the dependency in the remote platform,
  they therefore are removed and recreated.
The result is that tainting a resource causes _every_ resource in that list to change,
  which cascades to all dependent resources, and their dependencies...
This is how tainting one ssh key can destroy an entire infrastructure.
The count attribute instead can be used as a flag to turn a resource on or off, like a feature flag.
Generally this means there is some condition where the resource is not necessary, for instance, if a suitable resource is found in a data call.
  Use the count attribute with a conditional statement and set the count equal to 0 if the statement is false, or 1 if it is true,
  this will cause Terraform to ignore the resource unless it is "on" or count = 1.
Count can't be used with for_each, in which case if the for_each loop is empty you will get the same effect.

## Highly Opinionated Selector Files

These modules are not meant to be a general purpose alternative to using the AWS cli/api,
  they are a specifically purposed use case of that very large set of options.
With that in mind some modules will have a file which contains a redundant "locals" stanza.
This stanza will merge with the other locals at compile time, but represents a separate topic than the central stanza.
This file will provide a set of named configurations which the implementation module can call on to provision a resource.
This is a highly opinionated selection of configurations which should be labeled with a specific purpose.
Selector files like this allow users to choose a configuration that makes sense to them without researching configurations.
Most commonly, this is used for server configurations, but may also occur in other places like ami selection or higher level abstractions.
Generally this should provide some examples of working configurations so that users do not need to scour provider documentation.

## Select if Not Creating

Forcing the user to select a resource if they are not creating it allows outputs to be normalized, which allows easier construction of modules at a higher level.
If a "server" implementation module always returns information about a server, even when the information isn't necessary, then the composing module can just treat it like any other implementation of that module.
This provides a separation of concerns around data and logic allowing for less work adapting to specific implementations.

## Idempotent Modules

Terraform state allows modules to be idempotent within their context by default,
  but what if you want a module to be idempotent across an implementation (or multiple implementations)?
Combining "select if not creating", "count as a feature flag", and data calls we are able to generate objects only when they need to exist.
This technique allows you to, for example, only generate a VPC once (or never, if you create it manually) by querying the provider instead of generating the resource.
Modules need selectors to accomplish this, usually in the form of some kind of name.

## Parenthesis Around Ternaries

All ternary functions should be contained by parenthesis to avoid confusion.
Example: `attribute = ( booleanVariable ? whenTrue : whenFalse )`
This is especially helpful when using boolean expressions such as:
`attribute = ( variableToQuestion == "value" ? whenTrue : whenFalse )`

## All Variables Passed Through Locals

All variables should be passed as into the locals block and only local variables should be referenced in resources.
This reduces the need to change the same variable in many different places when it inevitably becomes necessary to make it more complex.
Many times, variables need to be processed after an initial implementation is in place,
  variables can not be processed in the variables section, and processing the variable in multiple places throughout the config is prone to error,
  this standard will prevent unnecessary changes to the variables and the config as a whole.
Basically, place everything in locals so you don't have to worry about moving them there later.

## Embedded Scripts Should Use Heredoc

Try to limit the frequency of embedded scripts, preferring `file` and `templatefile` function calls.
This allows CI to find and run shellcheck on all scripts (much harder to do if the script is embedded).
When you must use an embedded script, use heredoc syntax to ensure that maintainers are able to easily parse the script.
Example:

```
inline = [ <<-EOT
    # this is a simple script
    echo "hello world"
  EOT
]
```

```
command = <<-EOT
  # this is a simple script
  echo "hello world"
EOT
```

## Script Path in Connection Strings

When you need to provision things (remote-exec) you often need to generate a connection block.
Terraform by default copies remote-exec commands into a script on the remote machine, the default location for that script is /tmp.
On SELinux this can cause issues running remote provisioners, to avoid this problem altogether, always include the "script_path" attribute in the connection block.
Set the script path to some path available to the user you expect to run the script.

## Remote Access Through SSH Agent

The modules in this repo rely on a local SSH Agent for access to servers.
This helps keep server access information from accidentally leaking into the repo.
It is assumed that the user has a private/public ssh key pair for accessing servers over ssh,
  and that the private key is loaded into the environment before Terraform is run.
Modules *won't* include information for accessing servers remotely using a password,
  Terraform generally records everything and there is too much risk of a shared password leaking.
Modules *won't* generate or require private keys to be passed to Terraform, instead relying on SSH to manage that security aspect.

## Module Tiers

Terraform allows infinite nesting of modules, be very deliberate about how modules are nested and why.
Nested modules are hard to troubleshoot and maintain, limiting the level of nesting is important.
This paradigm was taken from the Pragmatic Programmers book.
This nesting does not include implementation modules.
Never nest local modules!
There shouldn't be more than 3 levels of nested independent modules: (Core, Primary, and Secondary)

### Core Modules

These independent modules represent provider resources, they should not have any nested independant modules.
Core Modules should only call resources.

### Primary Modules

These independent modules represent groups of core modules, they should not call resources.
Primary Modules should only call Core Modules.

### Secondary Modules

These modules represent large systems, they should only call Primary Modules.
Secondary Modules should only call Primary Modules.

## Test Size

### Unit

In this code base the smallest unit of code that is useful to test is the "local module".
Each local module should have its own test in the examples section under "unit", usually this means overriding the other units.
Please be careful when grouping resources into a local module, they should be as small as possible and logically coherent.

### Integration

In this code base an "integration" refers to testing multiple "units".
Integration tests show that any two local modules work together.

### E2E

In this code base an "End to End" or "E2E" test refers to testing all of the units together.
A module might have several E2E tests validating different configurations.
