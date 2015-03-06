![unihx logo](/extra/assets/unihx_logo_complete.png?raw=true)

Unity-Haxe tools. Compile to Unity3D from Haxe.

## Goal
Make Haxe be a first-class Unity development language, and make it easier to work with Haxe on Unity than the natively supported Unity languages

## Getting started
Use `haxelib git unihx https://github.com/unihx/unihx.git` to install it.

On an existing Unity project, run `haxelib run unihx init path/to/unity/proj`. Beware that you currently need a Haxe nightly build to be able to compile and use this library correctly.

## What works
You can see a demonstration of some of its features at http://waneck.github.io/wwx-unity3d-haxe/ . The following are working already:
 * When Unity gets back to focus, it compiles the changed .hx scripts
 * You can click & drag .hx scripts into the inspector, like you can do with pure C#/UnityScript scripts
 * The resulting C# files are compiled in a directory relative to the .hx script file - so you can create Editor scripts, etc more easily
 * You can access other C# scripts from within Haxe, and vice-versa - even those that are compiled within the same compilation unit!
 * Access to any .NET library through `-net-lib`
 * Extend MonoBehaviour and code like you would with other Unity languages. Be sure to check the wwx presentation to get an idea of the types equivalence (e.g. C#'s array are cs.NativeArray in Haxe)
 * Use the `@:nativeGen` metadata to generate very clean code
 * Error positions always shown in the .hx code
 * Operator overloading on core structures like Vector2, Vector3, Matrix4x4, Quaternion, etc. See more about it at [Core Structures](https://github.com/unihx/unihx/wiki/Core-Structures)
 
## What still needs work
 * The HaxeBehaviour class is available, but some of its features demonstrated were proof-of-concept and are currently only accessible through the development branch.

## Help wanted
Any kind of contribution will be much appreciated - from feature requests, testing it and adding bug reports, tutorials and documentation, to actual code and features!
Pull requests are very welcome, and if you are excited as we are to bring an awesome Haxe support to Unity, let us know and join the team!
