using UnityEngine;
using System.Collections;

public class TestEntryPoint : MonoBehaviour {

	// Use this for initialization
	void Start () {
		UnityTests.runTests(delegate(bool passed) {
			Debug.Log(passed);
		});
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
