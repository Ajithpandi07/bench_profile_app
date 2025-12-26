package com.example.bench_profile_app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel;
class MainActivity: FlutterFragmentActivity(), SensorEventListener {	private lateinit var sensorManager: SensorManager
	private var stepCounter: Sensor? = null
	private var heartRateSensor: Sensor? = null

	private var cumulativeSteps: Int = 0
	private var lastHeartRate: Float = 0.0f

	// Define the method channel name to match health_remote.dart
	private val HEALTH_CHANNEL = "bench_profile/health"
	private lateinit var channel: MethodChannel

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		// Setup the method channel
		channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HEALTH_CHANNEL)
		channel.setMethodCallHandler { call, result ->
			if (call.method == "getCurrentMetrics") {
				val metrics = mapOf(
					"source" to "sensors_android",
					"steps" to cumulativeSteps,
					"heartRate" to lastHeartRate,
					"timestamp" to System.currentTimeMillis()
				)
				result.success(metrics)
			} else {
				result.notImplemented()
			}
		}

		// Setup sensor manager
		sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
		stepCounter = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
		heartRateSensor = sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)
	}

	override fun onResume() {
		super.onResume()
		// Register listeners when the app is resumed
		stepCounter?.also {
			sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
		}
		heartRateSensor?.also {
			sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
		}
	}

	override fun onPause() {
		super.onPause()
		// Unregister listeners to save battery when the app is paused
		sensorManager.unregisterListener(this)
	}

	override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
		// Can be ignored for this use case
	}

	override fun onSensorChanged(event: SensorEvent?) {
		if (event == null) return

		when (event.sensor.type) {
			Sensor.TYPE_STEP_COUNTER -> {
				cumulativeSteps = event.values[0].toInt()
			}
			Sensor.TYPE_HEART_RATE -> {
				lastHeartRate = event.values[0]
			}
		}
	}
}
