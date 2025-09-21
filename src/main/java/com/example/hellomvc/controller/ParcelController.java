package com.example.hellomvc.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ParcelController {

    @GetMapping("/parcel")
    public String hello() {
        return "here is a parcel";
    }
}
