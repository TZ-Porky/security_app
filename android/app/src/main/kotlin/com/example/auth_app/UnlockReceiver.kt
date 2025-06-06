package com.example.auth_app // <-- Assurez-vous que c'est le bon package de votre application

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class UnlockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_USER_PRESENT) {
            Log.d("UnlockReceiver", "Événement ACTION_USER_PRESENT détecté. Lancement de l'application.")
            // Lancer votre MainActivity
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                // S'assurer que l'application est lancée en tant que nouvelle tâche si elle n'est pas déjà au premier plan
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                context.startActivity(launchIntent)
            } else {
                Log.e("UnlockReceiver", "Impossible de trouver l'intention de lancement pour le package: ${context.packageName}")
            }
        } else if (action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("UnlockReceiver", "Événement BOOT_COMPLETED détecté. Receiver enregistré.")
            // Pas besoin de lancer l'app ici, juste s'assurer que le receiver est prêt.
            // Le premier déverrouillage après le boot déclenchera ACTION_USER_PRESENT.
        }
    }
}