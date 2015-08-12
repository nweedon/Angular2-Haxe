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
package angular2haxe;

import haxe.rtti.Meta;
import js.Lib;
import angular2haxe.ng.Angular;
import angular2haxe.ng.ComponentAnnotation;
import angular2haxe.ng.DirectiveAnnotation;
import angular2haxe.ng.ViewAnnotation;

class Application
{	
	public function new(components : Array<Class<Dynamic>>) 
	{
		// Backwards compatibility. After alpha.28, the window
		// variable was named 'ng' instead of 'angular'.
		untyped window.angular = window.ng;
		bootstrap(components);
	}
	
	/**
	 * Bootstrap the application, which currently sets up component
	 * classes and their respective annotations ready for Angular 2.
	 * Once this is complete, angular.bootstrap is called for each
	 * component supplied.
	 * @param	components - An array of valid component classes
	 */
	private function bootstrap(components : Array<Class<Dynamic>>)
	{		
		var showDataInTrace : Bool = false;
		var validAnnotations : Map<String, AnnotationPair> = [
			"Component" => { annotation: ComponentAnnotation, extension: ComponentAnnotationExtension },
			"Directive" => { annotation: DirectiveAnnotation, extension: DirectiveAnnotationExtension },
			"View" 		=> { annotation: ViewAnnotation, extension: ViewAnnotationExtension },
		];
		
		for (component in components)
		{
			var anno = Meta.getType(component);			
			var className = Type.getClassName(component);
			
			if (Reflect.fields(component).indexOf('__alreadyConstructed') > -1)
			{
				Trace.warning('WARNING: ${className} is using experimental :build annotation feature.');
				
				// Parse Angular Object in annotations field. This has to be done
				// at runtime as all Angular Objects are external and do not resolve
				// at compile-time.
				var annotations : Array<Dynamic> = Reflect.field(component, "annotations");
				
				if (annotations != null)
				{
					// Annotations are built in the order:
					// Component, View, Directive (see BuildPlugin.hx)
					var metaNames : Array<String> = ["Component", "View", "Directive"];
					var index : Int = 0;
					
					// Filter out all null entries.
					for (index in 0...annotations.length)
					{
						if (annotations[index] == null) 
						{
							annotations.remove(null);
						}
					}
					
					index = 0;
					
					for (data in annotations)
					{
						// Call Annotation extension function to 
						// transform all string representations 
						// to Angular Object data
						Reflect.callMethod(	validAnnotations[metaNames[index]].extension, 
											Reflect.field(validAnnotations[metaNames[index]].extension, "postCompileTransform"),
											[data]);
											
						index++;
					}
				}
			}
			else
			{
				// Create 'annotations' and 'parameters' fields, so they don't have
				// to be added by a developer every time a new class is created.
				Reflect.setField(component, "annotations", []);
				Reflect.setField(component, "parameters", []);
				
				// Get the annotation and parameters fields from the component class.
				var annotations : Array<Dynamic> = Reflect.field(component, "annotations");
				var parameters : Array<Dynamic> = Reflect.field(component, "parameters");
				
				// Only bootstrap once.
				if (annotations != null && annotations.length == 0)
				{
					Trace.log('=> Bootstrapping ${className}');
						
					for(name in Reflect.fields(anno))
					{
						if (validAnnotations.exists(name))
						{
							var field = Reflect.field(anno, name);
							
							// Call AnnotationExtension transform function. This transform
							// function takes Haxe metadata input and transforms it into the
							// data that Angular 2 expects.
							// For example, Haxe metadata only handles constants (no class names),
							// so the string representations of the class names must be transformed into
							// JavaScript classes/functions at runtime.
							var input = field[0];
							
							var result = Reflect.callMethod(validAnnotations[name].extension, 
												Reflect.field(validAnnotations[name].extension, "transform"), 
												[input, annotations, parameters]);
							
							annotations.push(Type.createInstance(validAnnotations[name].annotation, [result]));
						}
						else
						{
							Trace.error(name + " is not a valid annotation.");
						}
					}
					
					if (showDataInTrace)
					{
						Trace.log('Annotations:\n${annotations}');
						Trace.log('Parameters:\n${parameters}');
					}
				}
				else
				{
					Trace.error('${className} does not have an "annotations" static variable in its class definition!');
				}
			}
			
			// Add event listener for Angular Bootstrap
			js.Browser.document.addEventListener("DOMContentLoaded", function()
			{				
				if (Reflect.fields(anno).indexOf("Component") >= 0)
				{
					Angular.bootstrap(component);
				}
				
				Trace.log('=> Finished bootstrapping ${className}');
			});
		}
	}
}