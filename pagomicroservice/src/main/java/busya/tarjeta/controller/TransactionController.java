package busya.tarjeta.controller;


import busya.tarjeta.controller.dto.PaymentDto;
import busya.tarjeta.model.Transaction;
import busya.tarjeta.service.TransactionService;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/payments")
public class TransactionController {

    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @Operation(summary = "Procesa un pago", description = "Recibe idClient, idCard, idDevice y amount")
    @PostMapping
    public ResponseEntity<Transaction> processPayment(@Valid @RequestBody PaymentDto paymentRequestDTO) {
        Transaction transaction = transactionService.processPayment(paymentRequestDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(transaction);
    }
}