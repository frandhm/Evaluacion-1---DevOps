/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.ropitadeluxe.backend;

import com.ropitadeluxe.backend.controller.RopaController;
import com.ropitadeluxe.backend.model.Ropa;
import com.ropitadeluxe.backend.repository.RopaRepository;
import java.util.List;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;


/**
 *
 * @author Fernando
 */
public class RopaControllerTest {
    @Test
    void testGetPlanes(){
        RopaRepository repository = Mockito.mock(RopaRepository.class);
        
        Ropa ropa1 = new Ropa ("Ropa 1", "Descripción 1", 10000.0, "imagen");
        Ropa ropa2 = new Ropa ("Ropa 2", "Descripción 2", 20000.0,"imagen");
        
        Mockito.when(repository.findAll()).thenReturn(List.of(ropa1,ropa2));
        
        RopaController controller = new RopaController(repository);
        
        List<Ropa> resultado = controller.getRopas();
        
        Assertions.assertEquals(2, resultado.size());
        Assertions.assertEquals("Ropa 1", resultado.get(0).getNombre());
    }
    
}