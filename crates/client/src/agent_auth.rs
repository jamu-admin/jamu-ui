// Copyright (c) 2025 Jamu Team
// Licensed under the Apache License, Version 2.0
//
// Part of Jamu Agent Platform
// Based on Zed Editor by Zed Industries, Inc.

//! Authentication module for Jamu Agent Platform
//!
//! This module handles user authentication with Supabase backend,
//! including token storage in system keychain, OAuth flows, and
//! token refresh logic.

use anyhow::{anyhow, Result};
use keyring::Entry;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;
use std::time::{SystemTime, UNIX_EPOCH};

/// Authentication token returned from Supabase
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthToken {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_at: i64,
    pub user: UserProfile,
}

/// User profile information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserProfile {
    pub id: String,
    pub email: String,
    pub tier: String,
    pub tokens_remaining: i64,
    pub daily_limit: i64,
}

/// Main authentication manager
pub struct AgentAuth {
    client: Client,
    base_url: String,
    anon_key: String,
    current_token: Option<AuthToken>,
}

impl AgentAuth {
    /// Create a new authentication manager
    pub fn new() -> Self {
        Self {
            client: Client::new(),
            base_url: env::var("SUPABASE_URL")
                .unwrap_or_else(|_| "https://placeholder.supabase.co".to_string()),
            anon_key: env::var("SUPABASE_ANON_KEY")
                .unwrap_or_else(|_| "placeholder-anon-key".to_string()),
            current_token: None,
        }
    }

    /// Create auth manager with custom configuration
    pub fn with_config(base_url: String, anon_key: String) -> Self {
        Self {
            client: Client::new(),
            base_url,
            anon_key,
            current_token: None,
        }
    }

    /// Login with email and password
    pub async fn login_email(&mut self, email: &str, password: &str) -> Result<AuthToken> {
        let response = self
            .client
            .post(format!(
                "{}/auth/v1/token?grant_type=password",
                self.base_url
            ))
            .header("apikey", &self.anon_key)
            .header("Content-Type", "application/json")
            .json(&serde_json::json!({
                "email": email,
                "password": password
            }))
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow!("Authentication failed: {}", error_text));
        }

        let auth_response: serde_json::Value = response.json().await?;

        // Extract basic auth info
        let access_token = auth_response["access_token"]
            .as_str()
            .ok_or_else(|| anyhow!("Missing access_token"))?
            .to_string();
        let refresh_token = auth_response["refresh_token"]
            .as_str()
            .ok_or_else(|| anyhow!("Missing refresh_token"))?
            .to_string();
        let expires_at = auth_response["expires_at"]
            .as_i64()
            .unwrap_or_else(|| {
                SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .unwrap()
                    .as_secs() as i64
                    + 3600
            });

        // Fetch user profile
        let profile = self.fetch_profile(&access_token).await?;

        let token = AuthToken {
            access_token,
            refresh_token,
            expires_at,
            user: profile,
        };

        // Store in keychain
        self.store_token(&token)?;
        self.current_token = Some(token.clone());

        Ok(token)
    }

    /// Generate OAuth URL for provider (Google, GitHub, etc.)
    pub fn generate_oauth_url(&self, provider: &str, redirect_uri: &str) -> Result<String> {
        let auth_url = format!(
            "{}/auth/v1/authorize?provider={}&redirect_to={}",
            self.base_url, provider, redirect_uri
        );

        Ok(auth_url)
    }

    /// Handle OAuth callback with authorization code
    pub async fn handle_oauth_callback(&mut self, code: &str) -> Result<AuthToken> {
        let response = self
            .client
            .post(format!("{}/auth/v1/token", self.base_url))
            .header("apikey", &self.anon_key)
            .header("Content-Type", "application/json")
            .json(&serde_json::json!({
                "grant_type": "authorization_code",
                "code": code
            }))
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow!("OAuth callback failed: {}", error_text));
        }

        let auth_response: serde_json::Value = response.json().await?;

        let access_token = auth_response["access_token"]
            .as_str()
            .ok_or_else(|| anyhow!("Missing access_token"))?
            .to_string();
        let refresh_token = auth_response["refresh_token"]
            .as_str()
            .ok_or_else(|| anyhow!("Missing refresh_token"))?
            .to_string();
        let expires_at = auth_response["expires_at"].as_i64().unwrap_or(0);

        let profile = self.fetch_profile(&access_token).await?;

        let token = AuthToken {
            access_token,
            refresh_token,
            expires_at,
            user: profile,
        };

        self.store_token(&token)?;
        self.current_token = Some(token.clone());

        Ok(token)
    }

    /// Refresh the current token
    pub async fn refresh_token(&mut self) -> Result<AuthToken> {
        let current = self
            .current_token
            .as_ref()
            .ok_or_else(|| anyhow!("No token to refresh"))?;

        let response = self
            .client
            .post(format!(
                "{}/auth/v1/token?grant_type=refresh_token",
                self.base_url
            ))
            .header("apikey", &self.anon_key)
            .header("Content-Type", "application/json")
            .json(&serde_json::json!({
                "refresh_token": current.refresh_token
            }))
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow!("Token refresh failed: {}", error_text));
        }

        let auth_response: serde_json::Value = response.json().await?;

        let access_token = auth_response["access_token"]
            .as_str()
            .ok_or_else(|| anyhow!("Missing access_token"))?
            .to_string();
        let refresh_token = auth_response["refresh_token"]
            .as_str()
            .unwrap_or(&current.refresh_token)
            .to_string();
        let expires_at = auth_response["expires_at"].as_i64().unwrap_or(0);

        let profile = self.fetch_profile(&access_token).await?;

        let token = AuthToken {
            access_token,
            refresh_token,
            expires_at,
            user: profile,
        };

        self.store_token(&token)?;
        self.current_token = Some(token.clone());

        Ok(token)
    }

    /// Fetch user profile from backend
    async fn fetch_profile(&self, access_token: &str) -> Result<UserProfile> {
        let response = self
            .client
            .get(format!("{}/rest/v1/profiles", self.base_url))
            .header("apikey", &self.anon_key)
            .header("Authorization", format!("Bearer {}", access_token))
            .header("Content-Type", "application/json")
            .send()
            .await?;

        if !response.status().is_success() {
            // Return default profile if fetch fails
            return Ok(UserProfile {
                id: String::new(),
                email: String::new(),
                tier: "free".to_string(),
                tokens_remaining: 10000,
                daily_limit: 10000,
            });
        }

        let profiles: Vec<serde_json::Value> = response.json().await?;

        if let Some(profile) = profiles.first() {
            Ok(UserProfile {
                id: profile["id"].as_str().unwrap_or("").to_string(),
                email: profile["email"].as_str().unwrap_or("").to_string(),
                tier: profile["tier"].as_str().unwrap_or("free").to_string(),
                tokens_remaining: profile["tokens_remaining"].as_i64().unwrap_or(10000),
                daily_limit: profile["daily_token_limit"].as_i64().unwrap_or(10000),
            })
        } else {
            Ok(UserProfile {
                id: String::new(),
                email: String::new(),
                tier: "free".to_string(),
                tokens_remaining: 10000,
                daily_limit: 10000,
            })
        }
    }

    /// Store token in system keychain
    fn store_token(&self, token: &AuthToken) -> Result<()> {
        let entry = Entry::new("jamu", "access-token")?;
        entry.set_password(&token.access_token)?;

        let refresh_entry = Entry::new("jamu", "refresh-token")?;
        refresh_entry.set_password(&token.refresh_token)?;

        // Store additional token data as JSON
        let token_data = serde_json::json!({
            "expires_at": token.expires_at,
            "user": token.user
        });
        let data_entry = Entry::new("jamu", "token-data")?;
        data_entry.set_password(&serde_json::to_string(&token_data)?)?;

        Ok(())
    }

    /// Load token from system keychain
    pub fn load_stored_token() -> Option<AuthToken> {
        let entry = Entry::new("jamu", "access-token").ok()?;
        let access_token = entry.get_password().ok()?;

        let refresh_entry = Entry::new("jamu", "refresh-token").ok()?;
        let refresh_token = refresh_entry.get_password().ok()?;

        let data_entry = Entry::new("jamu", "token-data").ok()?;
        let token_data_str = data_entry.get_password().ok()?;
        let token_data: serde_json::Value = serde_json::from_str(&token_data_str).ok()?;

        Some(AuthToken {
            access_token,
            refresh_token,
            expires_at: token_data["expires_at"].as_i64().unwrap_or(0),
            user: serde_json::from_value(token_data["user"].clone()).ok()?,
        })
    }

    /// Check if currently authenticated
    pub fn is_authenticated(&self) -> bool {
        self.current_token.is_some()
    }

    /// Get current access token
    pub fn get_token(&self) -> Option<String> {
        self.current_token
            .as_ref()
            .map(|t| t.access_token.clone())
    }

    /// Get current user profile
    pub fn get_user(&self) -> Option<&UserProfile> {
        self.current_token.as_ref().map(|t| &t.user)
    }

    /// Check if token is expired
    pub fn is_token_expired(&self) -> bool {
        if let Some(token) = &self.current_token {
            let now = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs() as i64;
            token.expires_at < now
        } else {
            true
        }
    }

    /// Logout and clear stored credentials
    pub async fn logout(&mut self) -> Result<()> {
        // Clear keychain
        if let Ok(entry) = Entry::new("jamu", "access-token") {
            let _ = entry.delete_password();
        }
        if let Ok(entry) = Entry::new("jamu", "refresh-token") {
            let _ = entry.delete_password();
        }
        if let Ok(entry) = Entry::new("jamu", "token-data") {
            let _ = entry.delete_password();
        }

        self.current_token = None;
        Ok(())
    }

    /// Update user profile (after backend changes)
    pub async fn update_profile(&mut self) -> Result<()> {
        let access_token = self
            .current_token
            .as_ref()
            .map(|t| t.access_token.clone());

        if let Some(token) = access_token {
            let profile = self.fetch_profile(&token).await?;
            if let Some(current) = &mut self.current_token {
                current.user = profile;
                // Clone before storing to avoid borrow checker issues
                let token_to_store = current.clone();
                self.store_token(&token_to_store)?;
            }
        }
        Ok(())
    }
}

impl Default for AgentAuth {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_auth_creation() {
        let auth = AgentAuth::new();
        assert!(!auth.is_authenticated());
    }

    #[test]
    fn test_oauth_url_generation() {
        let auth = AgentAuth::with_config(
            "https://test.supabase.co".to_string(),
            "test-key".to_string(),
        );

        let url = auth
            .generate_oauth_url("google", "jamu://auth/callback")
            .unwrap();
        assert!(url.contains("google"));
        assert!(url.contains("jamu://auth/callback"));
    }

    #[test]
    fn test_token_expiry_check() {
        let mut auth = AgentAuth::new();
        auth.current_token = Some(AuthToken {
            access_token: "test".to_string(),
            refresh_token: "test".to_string(),
            expires_at: 0, // Expired
            user: UserProfile {
                id: "test".to_string(),
                email: "test@test.com".to_string(),
                tier: "free".to_string(),
                tokens_remaining: 10000,
                daily_limit: 10000,
            },
        });

        assert!(auth.is_token_expired());
    }
}

