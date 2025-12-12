// Copyright (c) 2025 Jamu Team
// Licensed under the Apache License, Version 2.0
//
// Part of Jamu Agent Platform
// Based on Zed Editor by Zed Industries, Inc.

//! Login view for Jamu authentication

use client::agent_auth::AgentAuth;
use gpui::{
    actions, div, prelude::*, App, Context, DismissEvent, EventEmitter, FocusHandle, Focusable,
    FontWeight, SharedString, Task, Window,
};
use ui::prelude::*;

actions!(jamu, [
    /// Submit login form
    SubmitLogin,
    /// Cancel login
    CancelLogin,
]);

pub struct LoginView {
    email: SharedString,
    password: SharedString,
    error: Option<SharedString>,
    is_loading: bool,
    focus_handle: FocusHandle,
    _auth_task: Option<Task<()>>,
}

impl LoginView {
    pub fn new(cx: &mut Context<Self>) -> Self {
        Self {
            email: SharedString::from(""),
            password: SharedString::from(""),
            error: None,
            is_loading: false,
            focus_handle: cx.focus_handle(),
            _auth_task: None,
        }
    }

    pub fn set_email(&mut self, email: impl Into<SharedString>, cx: &mut Context<Self>) {
        self.email = email.into();
        cx.notify();
    }

    pub fn set_password(&mut self, password: impl Into<SharedString>, cx: &mut Context<Self>) {
        self.password = password.into();
        cx.notify();
    }

    fn submit(&mut self, _: &SubmitLogin, _: &mut Window, cx: &mut Context<Self>) {
        let email = self.email.to_string();
        let password = self.password.to_string();

        if email.is_empty() || password.is_empty() {
            self.error = Some("Email and password are required".into());
            cx.notify();
            return;
        }

        self.is_loading = true;
        self.error = None;
        cx.notify();

        self._auth_task = Some(cx.spawn(async move |this, cx| {
            let mut auth = AgentAuth::new();

            match auth.login_email(&email, &password).await {
                Ok(_token) => {
                    // Success! Token is now stored in keychain
                    log::info!("Authentication successful! Token stored.");
                    
                    // Update UI to show success
                    this.update(cx, |this, cx| {
                        this.error = Some("✅ Login successful! Please restart Jamu.".into());
                        this.is_loading = false;
                        cx.notify();
                    })
                    .ok();
                    
                    // Token is saved in keychain
                    // User needs to restart Jamu for workspace to open
                }
                Err(e) => {
                    this.update(cx, |this, cx| {
                        this.is_loading = false;
                        this.error = Some(format!("Login failed: {}", e).into());
                        cx.notify();
                    })
                    .ok();
                }
            }
        }));
    }

    fn cancel(&mut self, _: &CancelLogin, _: &mut Window, cx: &mut Context<Self>) {
        cx.emit(DismissEvent);
    }
}

impl EventEmitter<DismissEvent> for LoginView {}

impl Focusable for LoginView {
    fn focus_handle(&self, _cx: &App) -> FocusHandle {
        self.focus_handle.clone()
    }
}

impl Render for LoginView {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.theme();
        let email_text = if self.email.is_empty() {
            SharedString::from("email@example.com")
        } else {
            self.email.clone()
        };
        let email_color = if self.email.is_empty() {
            Color::Muted
        } else {
            Color::Default
        };
        let error = self.error.clone();
        let is_loading = self.is_loading;

        v_flex()
            .key_context("LoginView")
            .track_focus(&self.focus_handle)
            .on_action(cx.listener(Self::submit))
            .on_action(cx.listener(Self::cancel))
            .size_full()
            .items_center()
            .justify_center()
            .bg(theme.colors().elevated_surface_background)
            .child(
                v_flex()
                    .w(px(400.))
                    .p_6()
                    .gap_4()
                    .bg(theme.colors().surface_background)
                    .border_1()
                    .border_color(theme.colors().border)
                    .rounded_lg()
                    .shadow_lg()
                    // Logo/Title
                    .child(
                        v_flex()
                            .items_center()
                            .gap_2()
                            .child(
                                Label::new("Jamu Agent Platform")
                                    .size(LabelSize::Large)
                                    .weight(FontWeight::BOLD),
                            )
                            .child(Label::new("v0.0.1").size(LabelSize::Small).color(Color::Muted)),
                    )
                    // Error message
                    .when_some(error, |this, error| {
                        this.child(
                            div()
                                .p_2()
                                .bg(theme.status().error.opacity(0.1))
                                .border_1()
                                .border_color(theme.status().error.opacity(0.3))
                                .rounded_md()
                                .child(Label::new(error).color(Color::Error)),
                        )
                    })
                    // Email input placeholder
                    .child(
                        v_flex()
                            .gap_1()
                            .child(Label::new("Email").size(LabelSize::Small))
                            .child(
                                div()
                                    .p_2()
                                    .w_full()
                                    .bg(theme.colors().editor_background)
                                    .border_1()
                                    .border_color(theme.colors().border)
                                    .rounded_md()
                                    .child(Label::new(email_text).color(email_color)),
                            ),
                    )
                    // Password input placeholder
                    .child(
                        v_flex()
                            .gap_1()
                            .child(Label::new("Password").size(LabelSize::Small))
                            .child(
                                div()
                                    .p_2()
                                    .w_full()
                                    .bg(theme.colors().editor_background)
                                    .border_1()
                                    .border_color(theme.colors().border)
                                    .rounded_md()
                                    .child(Label::new("••••••••").color(Color::Muted)),
                            ),
                    )
                    // Sign in button
                    .child(
                        Button::new("sign_in", "Sign In")
                            .style(ButtonStyle::Filled)
                            .full_width()
                            .disabled(is_loading)
                            .on_click(move |_, _, _| {
                                // For now, just a placeholder
                                // Real input handling would need TextInput component
                                // OAuth buttons work for testing
                            }),
                    )
                    // Divider
                    .child(
                        h_flex()
                            .w_full()
                            .items_center()
                            .gap_2()
                            .child(div().flex_1().h(px(1.)).bg(theme.colors().border))
                            .child(Label::new("or").color(Color::Muted).size(LabelSize::Small))
                            .child(div().flex_1().h(px(1.)).bg(theme.colors().border)),
                    )
                    // OAuth buttons
                    .child(
                        v_flex()
                            .gap_2()
                            .child({
                                Button::new("google_oauth", "Continue with Google")
                                    .full_width()
                                    .on_click(|_, _window, cx| {
                                        let auth = AgentAuth::new();
                                        if let Ok(url) = auth.generate_oauth_url("google", "jamu://auth/callback") {
                                            cx.open_url(&url);
                                        }
                                    })
                            })
                            .child({
                                Button::new("github_oauth", "Continue with GitHub")
                                    .full_width()
                                    .on_click(|_, _window, cx| {
                                        let auth = AgentAuth::new();
                                        if let Ok(url) = auth.generate_oauth_url("github", "jamu://auth/callback") {
                                            cx.open_url(&url);
                                        }
                                    })
                            }),
                    )
                    // Sign up link
                    .child(
                        h_flex()
                            .w_full()
                            .justify_center()
                            .gap_1()
                            .child(Label::new("Don't have an account?").color(Color::Muted).size(LabelSize::Small))
                            .child(
                                Button::new("signup", "Sign Up")
                                    .style(ButtonStyle::Transparent)
                                    .on_click(|_, _, cx| {
                                        cx.open_url("https://jamu.app/signup");
                                    }),
                            ),
                    )
                    // Loading indicator
                    .when(is_loading, |this| {
                        this.child(
                            div()
                                .w_full()
                                .items_center()
                                .child(Label::new("Authenticating...").color(Color::Muted)),
                        )
                    }),
            )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use gpui::TestAppContext;

    #[gpui::test]
    fn test_login_view_creation(cx: &mut TestAppContext) {
        cx.update(|cx| {
            let view = cx.new(|cx| LoginView::new(cx));
            view.update(cx, |view, _| {
                assert_eq!(view.email, "");
                assert_eq!(view.password, "");
                assert!(!view.is_loading);
                assert!(view.error.is_none());
            });
        });
    }
}

