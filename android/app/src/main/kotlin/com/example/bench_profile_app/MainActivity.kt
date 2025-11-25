package com.example.bench_profile_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity(), SensorEventListener {
	private val CHANNEL = "bench_profile/health"
	private var sensorManager: SensorManager? = null
	private var stepSensor: Sensor? = null
	private var heartSensor: Sensor? = null

	private var latestStepCount: Float = -1f
	private var latestHeartRate: Float = -1f
	private var lastTs: Long = System.currentTimeMillis()

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
		stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
		heartSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_HEART_RATE)
		// register listeners if available
		stepSensor?.also { sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL) }
		heartSensor?.also { sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL) }
	}

	override fun onDestroy() {
		sensorManager?.unregisterListener(this)
		super.onDestroy()
	}

	override fun onSensorChanged(event: SensorEvent) {
		when (event.sensor.type) {
			Sensor.TYPE_STEP_COUNTER -> {
				latestStepCount = event.values[0]
				lastTs = System.currentTimeMillis()
			}
			Sensor.TYPE_HEART_RATE -> {
				latestHeartRate = event.values[0]
				lastTs = System.currentTimeMillis()
			}
		}
	}

	override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"getCurrentMetrics" -> {
					// Ensure we have sensor permission (BODY_SENSORS) on Android
					if (ContextCompat.checkSelfPermission(this, Manifest.permission.BODY_SENSORS) != PackageManager.PERMISSION_GRANTED) {
						result.error("NO_PERMISSION", "BODY_SENSORS permission not granted", null)
						return@setMethodCallHandler
					}

					val steps = if (latestStepCount >= 0f) latestStepCount.toInt() else null
					val hr = if (latestHeartRate >= 0f) latestHeartRate.toDouble() else null
					val map: MutableMap<String, Any?> = HashMap()
					map["source"] = "sensors"
					map["steps"] = steps
					map["heartRate"] = hr
					map["timestamp"] = System.currentTimeMillis()
					result.success(map)
				}
				else -> result.notImplemented()
			}
		}
	}
}