package busya.tarjeta.service;


import busya.tarjeta.controller.dto.PaymentDto;
import busya.tarjeta.model.Transaction;
import busya.tarjeta.repository.TransactionRepository;
import org.springframework.stereotype.Service;

@Service
public class TransactionServiceImpl implements TransactionService {

    private final TransactionRepository transactionRepository;

    public TransactionServiceImpl(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    @Override
    public Transaction processPayment(PaymentDto paymentRequestDTO) {
        Transaction transaction = new Transaction(
                paymentRequestDTO.getIdClient(),
                paymentRequestDTO.getIdCard(),
                paymentRequestDTO.getIdDevice(),
                paymentRequestDTO.getAmount()
        );

        return transactionRepository.save(transaction);
    }
}