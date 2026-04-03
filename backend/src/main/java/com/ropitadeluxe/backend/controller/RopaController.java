/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.ropitadeluxe.backend.controller;

import com.ropitadeluxe.backend.model.Ropa;
import com.ropitadeluxe.backend.repository.RopaRepository;
import java.util.List;
import org.springframework.web.bind.annotation.*;

/**
 *
 * @author Fernando
 */
@RestController
@RequestMapping("/api/ropas")
@CrossOrigin("*")
public class RopaController {
    private final RopaRepository repository;

    public RopaController(RopaRepository repository) {
        this.repository = repository;
    }
    
    @GetMapping
    public List<Ropa> getRopas(){
        return repository.findAll();
    }
}