package busya.tarjeta.service;


import busya.tarjeta.controller.dto.PaymentDto;
import busya.tarjeta.model.Transaction;

public interface TransactionService {

    Transaction processPayment(PaymentDto paymentDto);
}