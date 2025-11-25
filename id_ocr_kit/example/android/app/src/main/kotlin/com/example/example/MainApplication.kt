package com.example.example

import android.app.Application
import androidx.multidex.MultiDexApplication

class MainApplication : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        // MultiDex is automatically enabled via MultiDexApplication
    }
}

