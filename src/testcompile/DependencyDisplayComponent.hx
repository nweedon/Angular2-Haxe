/*
Copyright 2015 Niall Frederick Weedon

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package testcompile;

import ng.Angular;
import ng.LifecycleEvent;
import test.Dependency.MyDirective;

/*
 * Reference:
 * https://angular.io/docs/js/latest/guide/displaying-data.html
 */

@Component({ 
	selector: 'c-dependency-display',
	compileChildren: true
})
@View({ 
	directives: ["testcompile.Dependency", "testcompile.MyDirective", "testcompile.NgModelDirective"],
	templateUrl: "templates/dependency.tpl.html"
})
#if !macro
@:build(angular2haxe.buildplugin.BuildPlugin.compile())
#end
class DependencyDisplayComponent
{	
    public function new()
    {
    }
}
